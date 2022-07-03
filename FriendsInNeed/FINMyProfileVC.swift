//
//  FINMyProfileVC.swift
//  Help A Paw
//
//  Created by Milen Marinov on 25.06.22.
//  Copyright © 2022 Milen. All rights reserved.
//

import UIKit
import MBProgressHUD

class FINMyProfileVC: UIViewController {
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var phoneField: UITextField!
    @IBOutlet weak var password1Field: UITextField!
    @IBOutlet weak var password2Field: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        emailField.text = FINDataManager.shared().getUserEmail()
        nameField.text = FINDataManager.shared().getUserName()
        phoneField.text = FINDataManager.shared().getUserPhone()
    }
    
    @IBAction func onCloseButton(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func onSaveButton(_ sender: Any) {
        guard password1Field.text == password2Field.text
        else {
            showAlertViewControllerWithTitle(NSLocalizedString("Error", comment: ""), message: NSLocalizedString("password_fields_mismatch_error", comment: ""), actions: nil)
            return
        }
        
        var password: String?
        if password1Field.text != nil &&
           password2Field.text != nil &&
           !password1Field.text!.isEmpty &&
           !password2Field.text!.isEmpty {
            
            if (password1Field.text!.count < 8) {
                showAlertViewControllerWithTitle(NSLocalizedString("Error", comment: ""), message: NSLocalizedString("password_too_short_error", comment: ""), actions: nil)
                return
            }
            
            password = password1Field.text
        }
        
        let progressIndicator = MBProgressHUD.showAdded(to: view, animated: true)
        FINDataManager.shared().updateCurrentUser(withName: nameField.text, phone: phoneField.text, andPassword: password) { error in
            progressIndicator.hide(animated: true)
            guard error == nil else {
                self.showAlertViewControllerWithTitle(NSLocalizedString("Error", comment: ""), message: error!.message, actions: nil)
                return
            }
            
            self.dismiss(animated: true)
        }
    }
    
    @IBAction func onDeleteAccountButton(_ sender: Any) {
        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""),
                                     style: UIAlertAction.Style.default,
                                     handler: nil)
        let delete = UIAlertAction(title: NSLocalizedString("Delete", comment: ""),
                                   style: UIAlertAction.Style.destructive,
                                     handler:  { (action) in
            self.deleteAccount()
        })
        showAlertViewControllerWithTitle(NSLocalizedString("delete_account_title", comment: ""), message: NSLocalizedString("delete_account_message", comment: ""), actions: [cancel, delete])
    }
    
    func deleteAccount() {
        let progressIndicator = MBProgressHUD.showAdded(to: view, animated: true)
        FINDataManager.shared().deleteUserAccountwithCompletion { error in
            progressIndicator.hide(animated: true)
            guard error == nil
            else {
                self.showAlertViewControllerWithTitle(NSLocalizedString("Error", comment: ""), message: error!.message, actions: nil)
                return
            }
            
            self.dismiss(animated: true)
        }
    }
    
    @IBAction func onLogOutButton(_ sender: Any) {
        let progressIndicator = MBProgressHUD.showAdded(to: view, animated: true)
        FINDataManager.shared().logout { error in
            progressIndicator.hide(animated: true)
            guard error == nil
            else {
                self.showAlertViewControllerWithTitle(NSLocalizedString("Error", comment: ""), message: error!.message, actions: nil)
                return
            }
            
            self.dismiss(animated: true)
        }
    }
}
