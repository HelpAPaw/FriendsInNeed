//
//  AlertPresenter.swift
//  Help A Paw
//
//  Created by Mehmed Kadir on 19.11.17.
//  Copyright © 2017 Milen. All rights reserved.
//
import Foundation

@objc extension UIApplication {
   @objc class func topViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(base: selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}

@objc extension UIViewController {
    
 @objc   func showAlertViewControllerWithTitle(_ title:String, message:String, actions:[UIAlertAction]?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
    
        if let actions = actions {
            for action in actions {
                alert.addAction(action)
            }
        }
        else {
            let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""),
                                         style: UIAlertAction.Style.default,
                                         handler: nil)
            alert.addAction(okAction)
        }
    
        if let topController = UIApplication.topViewController() {
            topController.present(alert, animated: true, completion: nil)
        }
    }
}
