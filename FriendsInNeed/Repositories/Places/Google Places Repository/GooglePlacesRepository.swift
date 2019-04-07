//
//  GooglePlacesRepository.swift
//  Help A Paw
//
//  Created by Aleksandar Angelov on 3/16/19.
//  Copyright © 2019 Milen. All rights reserved.
//

import Foundation

class GooglePlacesRepository: PlacesRepository {
    
    let httpProvider: HTTPProvider
    
    init(httpProvider: HTTPProvider) {
        self.httpProvider = httpProvider
    }
    
    func veterinaryClinics(around location: CLLocationCoordinate2D, in radius: Double) -> RepositoryResult<[FINPlace]> {
        fatalError("not implemented")
    }
    
    func phoneNumber(for placeId: String) -> RepositoryResult<String> {
        fatalError("not implemented")
    }
    
}
