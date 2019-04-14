//
//  FINPrivacyPolicyVC.swift
//  Help A Paw
//
//  Created by Milen on 13/09/18.
//  Copyright © 2018 Milen. All rights reserved.
//

import UIKit

class FINPrivacyPolicyVC: UIViewController {
    @IBOutlet weak var toolbar: UIView!
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        toolbar.layer.shadowColor = UIColor.lightGray.cgColor
        toolbar.layer.shadowOpacity = 1.0
        toolbar.layer.shadowOffset = CGSize(width: 0, height: 2)
        
        webView.delegate = self
        let url = URL(string: "https://backendlessappcontent.com/***REMOVED***/***REMOVED***/files/web/privacypolicy.html");
        let request = URLRequest(url: url!)
        webView.loadRequest(request);
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        dismiss(animated: true) {}
    }
}

extension FINPrivacyPolicyVC: UIWebViewDelegate {
    func webViewDidStartLoad(_ webView: UIWebView) {
        loadingIndicator.startAnimating()
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        loadingIndicator.stopAnimating()
    }
}
