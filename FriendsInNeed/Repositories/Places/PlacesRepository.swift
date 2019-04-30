//
//  PlacesRepository.swift
//  Help A Paw
//
//  Created by Aleksandar Angelov on 3/16/19.
//  Copyright © 2019 Milen. All rights reserved.
//

import Foundation

@objc protocol PlacesRepository {
    
    /// Fetch the nearby veterinary clinics
    ///
    /// - Parameters:
    ///   - location: location of the search
    ///   - radius: radius around that location in meters
    ///   - openedNow: is clinic open now
    ///   - completionHandler: completion handler consisting of optional places and optional error
    @objc func veterinaryClinics(around location: CLLocationCoordinate2D, in radius: Double, openedNow: Bool, completionHandler: @escaping PlacesRepoVeterinaryClinicsCompletionHandler)
    
    /// Fetch a place details
    ///
    /// - Parameters:
    ///   - placeId: place id
    ///   - completionHandler: completion handler consisting of optional place details and optional error
    @objc func placeDetails(for placeId: String, completionHandler: @escaping PlacesRepoDetailsCompletionHandler)
    
}

// MARK: - Completion handler typealias
typealias PlacesRepoVeterinaryClinicsCompletionHandler = (_ places: [FINPlace]?, _ error: Error?) -> Void
typealias PlacesRepoDetailsCompletionHandler = (_ placeDetails: FINPlaceDetails?, _ error: Error?) -> Void

// MARK: - Errors
@objc enum PlacesRepositoryError: Int, Error, LocalizedError {
    
    case overQueryLimt
    case requestDenied
    case invalidRequest
    case decoding
    
    init?(status: String) {
        switch status {
        case "OVER_QUERY_LIMIT":
            self = .overQueryLimt
        case "REQUEST_DENIED":
            self = .requestDenied
        case "INVALID_REQUEST":
            self = .invalidRequest
        default:
            return nil
        }
        
    }
    
    var reason: String {
        switch self {
        case .overQueryLimt, .requestDenied, .invalidRequest:
            return "The service is not available at the moment"
        case .decoding:
            return "Unknown error occured. Please try again"
        }
    }
    
    var localizedDescription: String {
        return reason
    }
}
