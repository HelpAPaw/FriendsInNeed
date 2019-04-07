//
//  GooglePlacesBaseRouter.swift
//  Help A Paw
//
//  Created by Aleksandar Angelov on 3/22/19.
//  Copyright © 2019 Milen. All rights reserved.
//

import Foundation
import Alamofire

class GooglePlacesRouter: AlamofireBaseRouter {
    
    private let apiKey = ""
    
    private let endpoint: Endpoint
    
    init(endpoint: Endpoint) {
        self.endpoint = endpoint
    }
    
    var httpMethod: Alamofire.HTTPMethod {
        return .get
    }
    
    var encoding: Alamofire.ParameterEncoding? {
        return URLEncoding.default
    }
    
    var path: String {
        switch endpoint {
        case .placeDetails: return "/details/json?"
        case .veterinaryClinics: return "/nearbysearch/json?"
        }
    }
    
    var parameters: [String: Any] {
        var parameters: [String: Any] = ["key": apiKey]
        switch endpoint {
        case .veterinaryClinics(let location, let radius, let placeType, let openedNow):
            let stringLocation = "\(location.latitude),\(location.longitude)"
            parameters.merge(["location": stringLocation, "radius": radius, "type": placeType, "keyword": "clinic"],
                             uniquingKeysWith: { _, second in return second })
            if openedNow {
                parameters["opennow"] = true
            }
        case .placeDetails(let placeId):
            parameters.merge(["placeId": placeId, "fields": "international_phone_number,opening_hours"],
                             uniquingKeysWith: { _, second in return second })
        }
        return parameters
    }
    
    var baseUrl: String {
        return "https://maps.googleapis.com/maps/api/place"
    }
    
    func asUrlRequest() throws -> URLRequest {
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
        case veterinaryClinics(location: CLLocationCoordinate2D, radius: Double, placeType: String, openedNow: Bool)
        case placeDetails(placeId: String)
    }
    
}
