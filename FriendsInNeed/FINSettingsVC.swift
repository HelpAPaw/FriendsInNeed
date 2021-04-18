//
//  FINSettingsVC.swift
//  Help A Paw
//
//  Created by Milen on 23/09/18.
//  Copyright © 2018 Milen. All rights reserved.
//

import UIKit

enum Settings: Int, CaseIterable {
    case radius
    case timeout
    case types
}

class FINSettingsVC: UIViewController {
    var radiusValue: Int = 0
    var timeoutValue: Int = 0
    let kSliderCellHeight: CGFloat = 75.0
    let kReuseIdSliderCell = "SliderCell"
    let kReuseIdSignalTypesCell = "SignalTypesCell"
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadSettingsValues()
        
        navigationItem.title = NSLocalizedString("Settings", comment: "")
        let closeButton = UIBarButtonItem(image: UIImage(named: "ic_close_x"), style: .plain, target: self, action: #selector(closeButtonTapped(_:)))
        navigationItem.leftBarButtonItem = closeButton
        
        tableView.register(UINib(nibName: "FINSettingsSliderCell", bundle:nil), forCellReuseIdentifier: kReuseIdSliderCell)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: kReuseIdSignalTypesCell)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
                
        tableView.reloadData()
    }
    
    func loadSettingsValues() {
        
        radiusValue = (FINDataManager.shared()?.getRadiusSetting())!
        timeoutValue = (FINDataManager.shared()?.getTimeoutSetting())!
    }
    
    func saveSettingsValues() {
        
        FINDataManager.shared()?.setRadiusSetting(radiusValue)
        FINDataManager.shared()?.setTimeoutSetting(timeoutValue)
        FINDataManager.shared()?.saveSettings()
    }

    @objc func closeButtonTapped(_ sender: Any) {
        saveSettingsValues()
        dismiss(animated: true) {}
    }
}

extension FINSettingsVC: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Settings.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        
        switch indexPath.section {
        case Settings.radius.rawValue:
            let sliderCell = tableView.dequeueReusableCell(withIdentifier: kReuseIdSliderCell) as! FINSettingsSliderCell
            sliderCell.setup(with: "number_of_kilometers", min: 1, max: 100, currentValue: radiusValue)
            sliderCell.valueChangedCallback = radiusValueChanged
            cell = sliderCell
        case Settings.timeout.rawValue:
            let sliderCell = tableView.dequeueReusableCell(withIdentifier: kReuseIdSliderCell) as! FINSettingsSliderCell
            sliderCell.setup(with: "number_of_days", min: 1, max: 30, currentValue: timeoutValue)
            sliderCell.valueChangedCallback = timeoutValueChanged
            cell = sliderCell
        case Settings.types.rawValue:
            cell = tableView.dequeueReusableCell(withIdentifier: kReuseIdSignalTypesCell)!
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.text = FINDataManager.shared()?.getStringForSignalTypesSetting()
            cell.textLabel?.numberOfLines = 0
        default:
            cell = tableView.dequeueReusableCell(withIdentifier: kReuseIdSliderCell)!
            break;
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case Settings.radius.rawValue:
            return NSLocalizedString("Radius", comment: "")
        case Settings.timeout.rawValue:
            return NSLocalizedString("Signal timeout", comment: "")
        case Settings.types.rawValue:
            return NSLocalizedString("Types", comment: "")
        default:
            return "";
        }
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case Settings.radius.rawValue:
            return NSLocalizedString("The area around your current location at any moment that you want to be notified if new signals appear", comment: "")
        case Settings.timeout.rawValue:
            return NSLocalizedString("How old signals you want to be notified about", comment: "")
        case Settings.types.rawValue:
            return NSLocalizedString("signal_types_footer", comment: "")
        default:
            return "";
        }
    }
}

extension FINSettingsVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case Settings.radius.rawValue:
            return kSliderCellHeight
        case Settings.timeout.rawValue:
            return kSliderCellHeight
        default:
            return 75.0
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case Settings.types.rawValue:
            let typesVC = FINSignalTypesSettingsTVC()
            navigationController?.pushViewController(typesVC, animated: true)
            tableView.deselectRow(at: indexPath, animated: true)
        default:
            return
            //Do nothing
        }
    }
}

extension FINSettingsVC {
    func radiusValueChanged(to newValue: Int) {
        radiusValue = newValue
    }
    
    func timeoutValueChanged(to newValue: Int) {
        timeoutValue = newValue
    }
}
