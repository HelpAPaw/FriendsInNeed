//
//  FINShareVC.swift
//  Help A Paw
//
//  Created by Milen Marinov on 2.05.22.
//  Copyright © 2022 Milen. All rights reserved.
//

import UIKit

class FINShareVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func onCloseButton(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func onShareButton(_ sender: Any) {
        // text to share
        let text = NSLocalizedString("share_app_text", comment: "") + "https://helpapaw.app.link/install"
        
        // set up activity view controller
        let textToShare = [ text ]
        let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
                
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
    }
}
