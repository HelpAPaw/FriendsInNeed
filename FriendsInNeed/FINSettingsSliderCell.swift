//
//  FINSettingsSliderCell.swift
//  Help A Paw
//
//  Created by Milen on 23/09/18.
//  Copyright © 2018 Milen. All rights reserved.
//

import UIKit

class FINSettingsSliderCell: UITableViewCell {
    var unit = ""
    var min = 0
    var max = 100
    var lastStep: Float = 0.0
    public var valueChangedCallback: ((Int) -> Void)?
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var slider: UISlider!

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setup(with unit: String, min: Int, max: Int, currentValue: Int) {
        self.unit = unit
        self.min = min
        self.max = max
        
        slider.minimumValue = Float(min)
        slider.maximumValue = Float(max)
        slider.value = Float(currentValue)
        lastStep = slider.value
        updateLabel()
    }
    
    func updateLabel() {
        let format = NSLocalizedString(unit, comment: "")
        label.text = String.localizedStringWithFormat(format, Int(slider.value))
    }
    
    @IBAction func sliderDidMove(_ sender: Any) {
        // Make the slider jump in steps of 1 whole unit
        let newStep = roundf(slider.value)
        slider.value = newStep
        
        // If the value has changed - update the label and call the callback (if present)
        if newStep != lastStep  {
            lastStep = newStep
            updateLabel()
            if let valueChangedCallback = valueChangedCallback {
                valueChangedCallback(Int(newStep))
            }
        }
    }
}
