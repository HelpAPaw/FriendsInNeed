//
//  ShareAppPresenter.swift
//  Help A Paw
//
//  Created by Milen Marinov on 3.05.22.
//  Copyright © 2022 Milen. All rights reserved.
//

import Foundation

@objc extension UIViewController {
    
    @objc   func showShareAppActivity(from sourceView: UIView) {
        // text to share
        let text = NSLocalizedString("share_app_text", comment: "") + "https://helpapaw.app.link/install"

        // set up activity view controller
        let textToShare = [ text ]
        let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = sourceView // so that iPads won't crash
             
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
    }
}
