//
//  InputValidator.swift
//  FriendsInNeed
//
//  Created by Milen on 31/05/17.
//  Copyright © 2017 Milen. All rights reserved.
//

import Foundation
import UIKit

@objc class InputValidator: NSObject {
    static func validateInput(for fields: Array<UITextField>, message: String, parent: UIViewController) -> Bool {
        for textField in fields {
            guard let text = textField.text, !text.isEmpty else {
                // show error
                let alert = UIAlertController(title: NSLocalizedString("Ooops!", comment: ""), message: message, preferredStyle: .alert)
                let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { (action) in
                    alert.dismiss(animated: true, completion: {})
                })
                alert.addAction(okAction)
                parent.present(alert, animated: true, completion: {})
                
                return false
            }
        }
        
        return true
    }
}
