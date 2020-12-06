//
//  FINPrivacyPolicyVC.swift
//  Help A Paw
//
//  Created by Milen on 13/09/18.
//  Copyright © 2018 Milen. All rights reserved.
//

import UIKit
import WebKit

class FINPrivacyPolicyVC: UIViewController {
    @IBOutlet weak var toolbar: UIView!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        toolbar.layer.shadowColor = UIColor.lightGray.cgColor
        toolbar.layer.shadowOpacity = 1.0
        toolbar.layer.shadowOffset = CGSize(width: 0, height: 2)
        
        webView.navigationDelegate = self
        let url = URL(string: SharedConstants.kPrivacyPolicyUrl);
        let request = URLRequest(url: url!)
        webView.load(request)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        dismiss(animated: true) {}
    }
}

extension FINPrivacyPolicyVC: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        loadingIndicator.startAnimating()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingIndicator.stopAnimating()
    }
}
