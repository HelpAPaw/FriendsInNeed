//
//  FINSignalPhotoVC.swift
//  Help A Paw
//
//  Created by Mehmed Kadir on 20.11.17.
//  Copyright © 2017 Milen. All rights reserved.
//

import UIKit

/**
 inject dataSource into viewcontroller
 view controller must confort to this protocol, and implement the both functions
 result: private dataSource for the vc
 */
@objc protocol Injectable {
    //    associatedtype Model
    //
    @objc func inject(img:UIImage)
    @objc func assertDependencies()
}
@objc protocol imageDelegate {
    @objc func present(img:UIImage)
}


@objc class FINSignalPhotoVC: UIViewController,Injectable {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var closeButton: UIButton!
    
    var signalImage:UIImageView!
    var dispatchWorkItemShow: DispatchWorkItem?
    var dispatchWorkItemHide: DispatchWorkItem?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assertDependencies()
        scrollView.delegate = self
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    /**
     Creates work item to be executed for hidind and showing close button
     */
    fileprivate func dispatchWorkItem(for show:Bool)->DispatchWorkItem {
        return DispatchWorkItem { [weak self] in
            UIView.animate(withDuration: 0.3, animations: {
                self?.closeButton.alpha = show == true ? 1:0
            }, completion: { (_) in
            })
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        prepareAndShowImage()
    }
    
    // MARK: - Injectable
    func inject(img image: UIImage) {
        signalImage = UIImageView(image: image)
    }
    
    func assertDependencies() {
        guard signalImage != nil else { fatalError("Data source object not set!") }
    }
    
    fileprivate func prepareAndShowImage(){
        signalImage.contentMode = UIView.ContentMode.center
        scrollView.contentSize = signalImage.image!.size
        scrollView.addSubview(signalImage)
        prepareScollView(withSize: self.view.frame.size)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: {[weak self] ctx in
            self?.prepareScollView(withSize: size)
            }, completion: { ctx in })
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    //MARK:- Actions
    @IBAction func closeButtonAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    /**
     Prepare scrollView for presenttion
     @param size is scrollview size to present based on that zoom scales is determined and content is centered
     */
    fileprivate func  prepareScollView(withSize size:CGSize){
        let scrollViewFrame = signalImage.image!.size
        let scaleWidth = size.width/scrollViewFrame.width
        let scaleHeight = size.height/scrollViewFrame.height
        var minScale = min(scaleHeight, scaleWidth)
        if minScale > 1 {
            minScale = 1
        }
        scrollView.minimumZoomScale = minScale
        scrollView.maximumZoomScale = 0.8
        scrollView.zoomScale = minScale
        centerScrollViewContents(toSize: size)
    }
    /**
     Re-centers scrollview image wheneveer needed
     @param size is current size to which content is centered
     */
    fileprivate  func centerScrollViewContents(toSize:CGSize) {
        let boundsSize = toSize
        var contentsFrame = signalImage.frame
        if contentsFrame.size.width < boundsSize.width {
            contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2
        } else {
            contentsFrame.origin.x = 0
        }
        if contentsFrame.size.height < boundsSize.height {
            contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2
        } else {
            contentsFrame.origin.y = 0
        }
        signalImage.frame = contentsFrame
    }
    /**
     Shows and hides close button animated based on zoom scale
     for proper implemantation it uses 2 workItems for showing and hiding the close button
     before calling each workItem first ivalidates the other one
     */
    fileprivate func showHideCloseButton(basedON point:CGPoint) {
        if point.x == 0 {
            if closeButton.alpha == 0 {
                dispatchWorkItemHide?.cancel()
                dispatchWorkItemShow = dispatchWorkItem(for: true)
                DispatchQueue.main.async(execute: dispatchWorkItemShow!)
            }
        } else {
            if closeButton.alpha == 1 {
                dispatchWorkItemShow?.cancel()
                dispatchWorkItemHide = dispatchWorkItem(for: false)
                DispatchQueue.main.async(execute: dispatchWorkItemHide!)
            }
        }
    }
}

//MARK:- UIScrollViewDelegate
extension FINSignalPhotoVC:UIScrollViewDelegate {
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerScrollViewContents(toSize: self.view.frame.size)
        showHideCloseButton(basedON: scrollView.contentOffset)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return signalImage
    }
}
