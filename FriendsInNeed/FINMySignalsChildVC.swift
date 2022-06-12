//
//  FINMySignalsChildVC.swift
//  Help A Paw
//
//  Created by Milen Marinov on 11.06.22.
//  Copyright © 2022 Milen. All rights reserved.
//

import UIKit
import FirebaseCrashlytics

enum FINMySignalsType {
    case submitted
    case commented
}

class FINMySignalsChildVC: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var noSignalsLabel: UILabel!
    @IBOutlet weak var errorView: UIView!
    
    var type: FINMySignalsType
    var signals: [FINSignal] = []
    let dateFormatter = DateFormatter()
    
    init(type: FINMySignalsType) {
        self.type = type
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if type == .submitted {
            noSignalsLabel.text = NSLocalizedString("no_submitted_signals", comment: "")
        }
        else if type == .commented {
            noSignalsLabel.text = NSLocalizedString("no_commented_signals", comment: "")
        }
        self.tableView.register(UINib(nibName: "FINSignalListCell", bundle: nil), forCellReuseIdentifier: "reuseIdentifier")
        
        self.dateFormatter.dateStyle = .short
        self.dateFormatter.timeStyle = .short
        
        refresh()
    }
    
    @IBAction func onRetryButtonTapped(_ sender: Any) {
        refresh()
    }

    @objc fileprivate func refresh() {
        self.errorView.isHidden = true
        loadingIndicator.startAnimating()
        if type == .submitted {
            FINDataManager.shared().getSubmittedSignalsByCurrentUser(completionHandler: onRefreshResult(signals:error:))
        }
        else if type == .commented {
            FINDataManager.shared().getCommentedSignalsByCurrentUser(completionHandler: onRefreshResult(signals:error:))
        }        
    }
    
    func onRefreshResult(signals: [FINSignal]?, error: FINError?) {
        self.loadingIndicator.stopAnimating()
        guard error == nil,
              let signals = signals
        else {
            self.errorView.isHidden = false
            Crashlytics.crashlytics().record(error: NSError(domain: "", code: 1001, userInfo: ["message": error?.message ?? "Unknown error"]))
            return
        }
        
        self.signals = signals
        self.tableView.reloadData()
    }
}

extension FINMySignalsChildVC: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        noSignalsLabel.isHidden = signals.count != 0 || loadingIndicator.isAnimating
        return signals.count
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath) as! FINSignalListCell

        cell.setTitle(signals[indexPath.row].title)
        cell.setDate(self.dateFormatter.string(from: signals[indexPath.row].dateCreated))
        cell.setPhotoUrl(signals[indexPath.row].photoUrl)

        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
}

extension FINMySignalsChildVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let signalDetailsVC = FINSignalDetailsVC(signal: signals[indexPath.row], andAnnotation: nil)
        signalDetailsVC.modalPresentationStyle = .overFullScreen
        let navController = UINavigationController(rootViewController: signalDetailsVC)
        navController.modalPresentationStyle = .overFullScreen
        
        present(navController, animated: true) {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}
