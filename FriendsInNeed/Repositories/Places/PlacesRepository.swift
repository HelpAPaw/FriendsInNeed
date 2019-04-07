//
//  PlacesRepository.swift
//  Help A Paw
//
//  Created by Aleksandar Angelov on 3/16/19.
//  Copyright © 2019 Milen. All rights reserved.
//

import Foundation

protocol PlacesRepository {
    
    func veterinaryClinics(around location: CLLocationCoordinate2D, in radius: Double) -> RepositoryResult<[FINPlace]>
    func phoneNumber(for placeId: String) -> RepositoryResult<String>
    
}
