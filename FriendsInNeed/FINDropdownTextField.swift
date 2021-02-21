//
//  FINDropdownTextView.swift
//  Help A Paw
//
//  Created by Milen Marinov on 21.02.21.
//  Copyright © 2021 Milen. All rights reserved.
//

import UIKit

class FINDropdownTextField: UITextField {
    
    // We don't want copy/paste in dropdown field
    override public func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {

        return false
    }
}
