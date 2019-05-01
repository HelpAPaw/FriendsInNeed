//
//  GooglePlacesBaseRouter.swift
//  Help A Paw
//
//  Created by Aleksandar Angelov on 3/22/19.
//  Copyright © 2019 Milen. All rights reserved.
//

import Foundation
import Alamofire

class FINGooglePlacesRouter: FINAlamofireBaseRouter {
    
    private let apiKey = ""
    
    private let endpoint: Endpoint
    
    init(endpoint: Endpoint) {
        self.endpoint = endpoint
    }
    
    var httpMethod: Alamofire.HTTPMethod {
        return .get
    }
    
    var encoding: Alamofire.ParameterEncoding? {
        return URLEncoding.queryString
    }
    
    var path: String {
        switch endpoint {
        case .placeDetails: return "/details/json"
        case .veterinaryClinics: return "/nearbysearch/json"
        }
    }
    
    var parameters: [String: Any] {
        var parameters: [String: Any] = ["key": apiKey]
        switch endpoint {
        case .veterinaryClinics(let location, let radius, let placeType, let openedNow):
            let stringLocation = "\(location.latitude),\(location.longitude)"
            var stringPlaceType = ""
            switch placeType {
            case .veterinaryClinic:
                stringPlaceType = "veterinary_care"
            }
            parameters.merge(["location": stringLocation, "radius": radius, "type": stringPlaceType, "keyword": "clinic"],
                             uniquingKeysWith: { _, second in return second })
            if openedNow {
                parameters["opennow"] = true
            }
        case .placeDetails(let placeId):
            parameters.merge(["placeid": placeId, "fields": "international_phone_number,opening_hours"],
                             uniquingKeysWith: { _, second in return second })
        }
        return parameters
    }
    
    var baseUrl: String {
        return "https://maps.googleapis.com/maps/api/place"
    }
    
    func asUrlRequest() -> URLRequest {
        guard var url = URL(string: baseUrl) else {
            fatalError("URL is invalid")
        }
        url.appendPathComponent(path)
        
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue
        if let encoding = self.encoding {
            return try! encoding.encode(request, with: parameters)
        }
        
        return request
    }
    
    enum Endpoint {
        case veterinaryClinics(location: CLLocationCoordinate2D, radius: Double, placeType: FINPlaceType, openedNow: Bool)
        case placeDetails(placeId: String)
    }
    
}
