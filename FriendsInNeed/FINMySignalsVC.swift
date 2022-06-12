//
//  MySignalsVC.swift
//  Help A Paw
//
//  Created by Milen Marinov on 8.05.22.
//  Copyright © 2022 Milen. All rights reserved.
//

import UIKit

class FINMySignalsVC: UIViewController {

    @IBOutlet weak var segmentedView: UISegmentedControl!
    @IBOutlet weak var contentView: UIView!
    let submittedVC = FINMySignalsChildVC(type: .submitted)
    let commentedVC = FINMySignalsChildVC(type: .commented)
    lazy var viewControllers = {
        [submittedVC, commentedVC]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        displayContentController(content: viewControllers.first!)
    }
    
    func displayContentController(content: UIViewController) {
        addChild(content)
        var frame = self.contentView.frame
        frame.origin.x = 0.0
        frame.origin.y = 0.0
        content.view.frame = frame
        self.contentView.addSubview(content.view)
        content.didMove(toParent: self)
    }
    
    func hideContentController(content: UIViewController) {
        content.willMove(toParent: nil)
        content.view.removeFromSuperview()
        content.removeFromParent()
    }
    
    @IBAction func onCloseButton(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func onSegmentedViewChanged(_ sender: Any) {
        let newVC = viewControllers[segmentedView.selectedSegmentIndex]
        let oldVC = viewControllers.first { vc in
            vc != newVC
        }
        guard let oldVC = oldVC
        else { return }
        hideContentController(content: oldVC)
        displayContentController(content: newVC)
    }
}
