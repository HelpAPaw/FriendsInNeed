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
        
        FINDataManager.shared().getAllSignals { (signals, error) in
            if let signals = signals {
                var unsolved = 0
                var ontheway = 0
                var solved = 0
                for signal in signals {
                    switch signal.status {
                    case FINSignalStatus.status0:
                        unsolved += 1
                    case .status1:
                        ontheway += 1
                    case .status2:
                        solved += 1
                        print("\(String(describing: signal.title))")
                    case .status3:
                        print("WTF!?")
                    @unknown default:
                        print("WTF!?!?")
                    }
                }
                self.lbHelpNeeded.text = "\(unsolved) Help needed"
                self.lbOnTheWay.text = "\(ontheway) Somebody On The Way"
                self.lbSolved.text = "\(solved) Solved"
                self.lbTotal.text = "\(signals.count) Total"
                print("Total signals: \(signals.count), unsolved: \(unsolved), ontheway: \(ontheway), solved: \(solved)")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onCloseButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}
