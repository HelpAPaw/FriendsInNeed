//
//  FINPlace.swift
//  Help A Paw
//
//  Created by Aleksandar Angelov on 3/10/19.
//  Copyright © 2019 Milen. All rights reserved.
//

import Foundation

final class FINPlace {
    
    let placeId: String
    
    let name: String
    
    let location: CLLocationCoordinate2D
    
    let iconUrl: URL?
    
    let vicinity: String
    
    let opened: Bool
    
    let rating: Double
    
    let totalUsersRating: Int
    
    let type: FINPlaceType
    
    init(placeId: String, name: String, location: CLLocationCoordinate2D, iconUrl: URL?, vicinity: String,
         opened: Bool, rating: Double, totalUsersRating: Int, type: FINPlaceType) {
        self.placeId = placeId
        self.name = name
        self.location = location
        self.iconUrl = iconUrl
        self.vicinity = vicinity
        self.opened = opened
        self.rating = rating
        self.totalUsersRating = totalUsersRating
        self.type = type
    }
    
}

extension FINPlace: Decodable {

    private enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case name
        case geometry
        case iconUrl = "icon"
        
        
        enum Geometry: String, CodingKey {
            case location
            
            enum Location {
                case lat
                case lng
            }
        }
        
    }
    
    convenience init(from decoder: Decoder) throws {
        fatalError()
    }

}
