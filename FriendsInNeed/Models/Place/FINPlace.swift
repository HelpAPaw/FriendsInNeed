//
//  FINPlace.swift
//  Help A Paw
//
//  Created by Aleksandar Angelov on 3/10/19.
//  Copyright © 2019 Milen. All rights reserved.
//

import Foundation

@objc final class FINPlace: NSObject {
    
    @objc let placeId: String
    
    @objc let name: String
    
    @objc let location: CLLocationCoordinate2D
    
    @objc let iconUrl: URL?
    
    @objc let vicinity: String
    
    @objc let isOpenNow: Bool
    
    @objc let rating: Double
    
    @objc let totalUsersRating: Int
    
    @objc let type: FINPlaceType
    
    @objc init(placeId: String, name: String, location: CLLocationCoordinate2D, iconUrl: URL?, vicinity: String,
         isOpenNow: Bool, rating: Double, totalUsersRating: Int, type: FINPlaceType) {
        self.placeId = placeId
        self.name = name
        self.location = location
        self.iconUrl = iconUrl
        self.vicinity = vicinity
        self.isOpenNow = isOpenNow
        self.rating = rating
        self.totalUsersRating = totalUsersRating
        self.type = type
    }
    
}
