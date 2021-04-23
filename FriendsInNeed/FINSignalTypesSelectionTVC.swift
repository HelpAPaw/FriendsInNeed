//
//  FINSignalTypesSettingsTableViewController.swift
//  Help A Paw
//
//  Created by Milen Marinov on 11.04.21.
//  Copyright © 2021 Milen. All rights reserved.
//

import UIKit

@objc protocol FINSignalTypesSelectionDelegate {
    func signalTypesSelectionFinished(with newTypesSelection: [NSNumber])
}

class FINSignalTypesSelectionTVC: UITableViewController {
    
    let kReuseIdentifier = "kReuseIdentifier"
    let signalTypes = FINDataManager.shared()!.signalTypes!
    let delegate: FINSignalTypesSelectionDelegate
    var settings: [Bool]
    
    @objc init(with selectedTypes:[NSNumber], and delegate: FINSignalTypesSelectionDelegate) {
        self.delegate = delegate
        
        settings = selectedTypes.map({ (numberSetting) -> Bool in
            numberSetting.boolValue
        })
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: kReuseIdentifier)
        
        navigationItem.title = NSLocalizedString("Types", comment: "")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        delegate.signalTypesSelectionFinished(with: settings.map({ (boolSetting) -> NSNumber in
            NSNumber(booleanLiteral: boolSetting)
        }))
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return signalTypes.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kReuseIdentifier, for: indexPath)

        cell.textLabel?.text = signalTypes[indexPath.row]
        cell.accessoryType = settings[indexPath.row] ? .checkmark : .none

        return cell
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        settings[indexPath.row] = !settings[indexPath.row]
        
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = settings[indexPath.row] ? .checkmark : .none
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
