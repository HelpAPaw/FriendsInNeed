//
//  FINStatusHelper.swift
//  FriendsInNeed
//
//  Created by Milen on 10/06/17.
//  Copyright © 2017 Milen. All rights reserved.
//

import Foundation

class FINStatusHelper: NSObject {
    static func getStatusNameForCode(_ code: Int) -> String {
        switch code {
        case 2:
            return NSLocalizedString("Solved", comment: "")
        case 1:
            return NSLocalizedString("Somebody on the way", comment: "")
        default:            
            return NSLocalizedString("Help needed", comment: "")
        }
    }
    
    static func getStatusImageForCode(_ code: Int) -> UIImage {
        switch code {
        case 2:
            return #imageLiteral(resourceName: "pin_green.png")
        case 1:
            return #imageLiteral(resourceName: "pin_orange.png")
        default:
            return #imageLiteral(resourceName: "pin_red.png")
        }
    }
}
