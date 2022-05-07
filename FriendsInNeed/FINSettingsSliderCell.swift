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
    //Callback for changes that has the option to transform the linear scale into e.g. logarithmic one
    lazy var valueChangedCallback: ((Float) -> Int) = {
        func f(value: Float) -> Int {
            return Int(value)
        }
        return f
    }()
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var slider: UISlider!

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setup(with unit: String, min: Int, max: Int, currentValue: Int, callback: @escaping ((Float) -> Int)) {
        self.selectionStyle = .none
        
        self.unit = unit
        self.min = min
        self.max = max
        self.valueChangedCallback = callback
        
        slider.minimumValue = Float(min)
        slider.maximumValue = Float(max)
        slider.value = Float(currentValue)
        updateValue()
    }
    
    func updateValue() {
        let valueToShow = valueChangedCallback(slider.value)
        updateLabel(valueToShow: valueToShow)
    }
    
    func updateLabel(valueToShow: Int) {
        let format = NSLocalizedString(unit, comment: "")
        label.text = String.localizedStringWithFormat(format, valueToShow)
    }
    
    @IBAction func sliderDidMove(_ sender: Any) {
        updateValue()
    }
}
