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
}

class FINSettingsVC: UIViewController {
    var radiusValue: Int = 0
    let radiusValueDefault = 10
    let kRadiusValueKey = "kRadiusValueKey"
    var timeoutValue: Int = 0
    let timeoutValueDefault = 5
    let kTimeoutValueKey = "kTimeoutValueKey"
    let kSliderCellHeight: CGFloat = 75.0
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var toolbar: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadSettingsValues()
        
        titleLabel.text = NSLocalizedString("Settings", comment: "")
        
        toolbar.layer.shadowColor = UIColor.lightGray.cgColor
        toolbar.layer.shadowOpacity = 1.0
        toolbar.layer.shadowOffset = CGSize(width: 0, height: 2)
        
        tableView.register(UINib(nibName: "FINSettingsSliderCell", bundle:nil), forCellReuseIdentifier: "SliderCell")
    }
    
    func loadSettingsValues() {
        let radiusValueSaved = UserDefaults.standard.integer(forKey: kRadiusValueKey)
        radiusValue = radiusValueSaved != 0 ? radiusValueSaved : radiusValueDefault
        
        let timeoutValueSaved = UserDefaults.standard.integer(forKey: kTimeoutValueKey)
        timeoutValue = timeoutValueSaved != 0 ? timeoutValueSaved : timeoutValueDefault
    }
    
    func saveSettingsValues() {
        UserDefaults.standard.set(radiusValue, forKey: kRadiusValueKey)
        UserDefaults.standard.set(timeoutValue, forKey: kTimeoutValueKey)
        UserDefaults.standard.synchronize()
    }

    @IBAction func closeButtonTapped(_ sender: Any) {
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
            let sliderCell = tableView.dequeueReusableCell(withIdentifier: "SliderCell") as! FINSettingsSliderCell
            sliderCell.setup(with: "number_of_kilometers", min: 1, max: 100, currentValue: radiusValue)
            sliderCell.valueChangedCallback = radiusValueChanged
            cell = sliderCell
        case Settings.timeout.rawValue:
            let sliderCell = tableView.dequeueReusableCell(withIdentifier: "SliderCell") as! FINSettingsSliderCell
            sliderCell.setup(with: "number_of_days", min: 1, max: 30, currentValue: timeoutValue)
            sliderCell.valueChangedCallback = timeoutValueChanged
            cell = sliderCell
        default:
            cell = tableView.dequeueReusableCell(withIdentifier: "SliderCell")!
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
            return 44.0
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
