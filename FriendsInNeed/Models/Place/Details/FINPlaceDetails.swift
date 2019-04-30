//
//  FINPlaceDetails.swift
//  Help A Paw
//
//  Created by Aleksandar Angelov on 4/14/19.
//  Copyright © 2019 Milen. All rights reserved.
//

import Foundation

@objc final class FINPlaceDetails: NSObject {
    
    @objc let placeId: String
    
    @objc let phoneNumber: String
    
    @objc let openingHours: FINPlaceOpeningHours
    
    init(placeId: String, phoneNumber: String, openingHours: FINPlaceOpeningHours) {
        self.placeId = placeId
        self.phoneNumber = phoneNumber
        self.openingHours = openingHours
    }
    
}
