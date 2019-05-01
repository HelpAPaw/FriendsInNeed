//
//  GooglePlacesRepository.swift
//  Help A Paw
//
//  Created by Aleksandar Angelov on 3/16/19.
//  Copyright © 2019 Milen. All rights reserved.
//

import Foundation
import Crashlytics

class FINGooglePlacesRepository: NSObject, FINPlacesRepository {
    
    private let httpProvider: FINAlamofireProvider
    
    private let mapper: FINGooglePlacesRepositoryMapper
    
    private let crashlytics = Crashlytics.sharedInstance()
    
    @objc override init() {
        self.httpProvider = FINAlamofireProvider()
        self.mapper = FINGooglePlacesRepositoryMapper()
    }
    
    // MARK: - Queries
    /// Fetch the nearby veterinary clinics
    ///
    /// - Parameters:
    ///   - location: location of the search
    ///   - radius: radius around that location in meters
    ///   - openedNow: is clinic open now
    ///   - completionHandler: completion handler consisting of optional places and optional error
    @objc func veterinaryClinics(around location: CLLocationCoordinate2D, in radius: Double, openedNow: Bool, completionHandler: @escaping PlacesRepoVeterinaryClinicsCompletionHandler) {
        let router = FINGooglePlacesRouter(endpoint: .veterinaryClinics(location: location, radius: radius, placeType: .veterinaryClinic, openedNow: openedNow))
        let urlRequest = router.asUrlRequest()
        
        httpProvider.request(urlRequest, completionHandler: { [weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case .success(let jsonDict):
                let additionalErrorUserInfo: [String: Any] = ["decoding_subject": "\(#file) \(#function) places decoding", "json": jsonDict]
                if let error = self.mapper.placesRepositoryError(from: jsonDict) {
                    completionHandler(nil, error)
                    self.crashlytics.recordError(error, withAdditionalUserInfo: additionalErrorUserInfo)
                    return
                }
                if let places = self.mapper.places(from: jsonDict) {
                    completionHandler(places, nil)
                } else {
                    let error = PlacesRepositoryError.decoding
                    completionHandler(nil, error)
                    self.crashlytics.recordError(error, withAdditionalUserInfo: additionalErrorUserInfo)
                }
            case .error(let error):
                completionHandler(nil, error)
                self.crashlytics.recordError(error)
            }
        })
    }
    
    /// Fetch a place details
    ///
    /// - Parameters:
    ///   - placeId: place id
    ///   - completionHandler: completion handler consisting of optional place details and optional error
    @objc func placeDetails(for placeId: String, completionHandler: @escaping PlacesRepoDetailsCompletionHandler) {
        let router = FINGooglePlacesRouter(endpoint: .placeDetails(placeId: placeId))
        let urlRequest = router.asUrlRequest()
        
        httpProvider.request(urlRequest, completionHandler: { result in
            switch result {
            case .success(let jsonDict):
                let additionalErrorUserInfo: [String: Any] = ["decoding_subject": "\(#file) \(#function) places decoding", "json": jsonDict]
                if let error = self.mapper.placesRepositoryError(from: jsonDict) {
                    completionHandler(nil, error)
                    self.crashlytics.recordError(error, withAdditionalUserInfo: additionalErrorUserInfo)
                    return
                }
                if let placeDetails = self.mapper.placeDetails(from: jsonDict, placeId: placeId) {
                    completionHandler(placeDetails, nil)
                } else {
                    let error = PlacesRepositoryError.decoding
                    completionHandler(nil, error)
                    self.crashlytics.recordError(error, withAdditionalUserInfo: additionalErrorUserInfo)
                }
            case .error(let error):
                completionHandler(nil, error)
                self.crashlytics.recordError(error)
            }
        })
    }
    
}
