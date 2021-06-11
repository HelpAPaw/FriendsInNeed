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
    static func validateInput(for fields: Array<UITextInput>, message: String, parent: UIViewController, validator: (String?) -> Bool) -> Bool {
        for textInput in fields {
            if !validator(textInput.text(in: textInput.textRange(from: textInput.beginningOfDocument, to: textInput.endOfDocument)!)) {
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
    
    @objc static func validateGeneralInput(for fields: Array<UITextInput>, message: String, parent: UIViewController) -> Bool {
        return validateInput(for: fields, message: message, parent: parent, validator: hasText(testStr:))
    }
    
    @objc static func validateDefaultMinMaxLengthInput(for fields: Array<UITextInput>, message: String, parent: UIViewController) -> Bool {
        return validateInput(for: fields, message: message, parent: parent, validator: hasMinMaxLength(testStr:))
    }
    
    @objc static func validateEmail(for fields: Array<UITextInput>, message: String, parent: UIViewController) -> Bool {
        return validateInput(for: fields, message: message, parent: parent, validator: isValidEmail(_:))
    }
    
    static func hasText(testStr: String?) -> Bool {
        
        if !(testStr?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)! {
            return true
        }
        
        return false
    }
    
    static func hasMinMaxLength(testStr: String?) -> Bool {
        guard testStr != nil else { return false }
        
        let lengthRegEx = "^.{10,512}$"
        
        let lengthTest = NSPredicate(format:"SELF MATCHES %@", lengthRegEx)
        return lengthTest.evaluate(with: testStr)
    }
    
    @objc static func isValidEmail(_ testStr:String?) -> Bool {
        
        guard testStr != nil else { return false }
        
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
}
