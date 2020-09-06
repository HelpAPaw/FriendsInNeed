//
//  FINAdminVC.swift
//  Help A Paw
//
//  Created by Milen on 03/06/18.
//  Copyright © 2018 Milen. All rights reserved.
//

import UIKit

class FINAdminVC: UIViewController {
    @IBOutlet weak var lbHelpNeeded: UILabel!
    @IBOutlet weak var lbOnTheWay: UILabel!
    @IBOutlet weak var lbSolved: UILabel!
    @IBOutlet weak var lbTotal: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        FINDataManager.shared()?.getTotalSignalCount(completionHandler: { (count, error) in
            if (error == nil) {
                self.lbTotal.text = "\(count) Total"
            }
        })
        
        FINDataManager.shared()?.getCountForSignals(with: FINSignalStatus.status0, withCompletionHandler: { (count, error) in
            if (error == nil) {
                self.lbHelpNeeded.text = "\(count) Help needed"
            }
        })
        
        FINDataManager.shared()?.getCountForSignals(with: FINSignalStatus.status1, withCompletionHandler: { (count, error) in
            if (error == nil) {
                self.lbOnTheWay.text = "\(count) Somebody On The Way"
            }
        })
        
        FINDataManager.shared()?.getCountForSignals(with: FINSignalStatus.status2, withCompletionHandler: { (count, error) in
            if (error == nil) {
                self.lbSolved.text = "\(count) Solved"
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onCloseButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}
