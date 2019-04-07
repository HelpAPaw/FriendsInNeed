//
//  HTTPProvider.swift
//  Help A Paw
//
//  Created by Aleksandar Angelov on 3/22/19.
//  Copyright © 2019 Milen. All rights reserved.
//

import Foundation

protocol HTTPProvider {
    
    func request(_ request: URLRequest, completionHandler: @escaping (RepositoryResult<[String:Any]>) -> Void)
    
}

enum HTTPError: Error, LocalizedError {
    case network(reason: String)
    case decoding
    
    var reason: String {
        switch self {
        case .network(let reason):
            return reason
        case .decoding:
            return "The data is corrupted"
        }
    }
    
    var localizedDescription: String {
        return reason
    }
}
