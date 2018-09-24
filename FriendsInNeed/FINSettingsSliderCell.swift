//
//  FINSettingsSliderCell.swift
//  Help A Paw
//
//  Created by Milen on 23/09/18.
//  Copyright © 2018 Milen. All rights reserved.
//

import UIKit

class FINSettingsSliderCell: UITableViewCell {
    var units: [String] = []
    var min = 0
    var max = 100
    var lastStep: Float = 0.0
    public var valueChangedCallback: ((Int) -> Void)?
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var slider: UISlider!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setup(with units: [String], min: Int, max: Int, currentValue: Int) {
        self.units = units
        self.min = min
        self.max = max
        
        slider.minimumValue = Float(min)
        slider.maximumValue = Float(max)
        slider.value = Float(currentValue)
        lastStep = slider.value
        updateLabel()
    }
    
    func updateLabel() {
        var unit = self.units[0]
        
        // If value is plural - add "s" to the unit
        if slider.value > 1 {
            unit = self.units[1]
        }
        
        label.text = String.init(format: "%.0f %@", slider.value, unit)
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
