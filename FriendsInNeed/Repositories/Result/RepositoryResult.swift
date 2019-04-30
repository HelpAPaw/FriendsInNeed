//
//  RepositoryResult.swift
//  Help A Paw
//
//  Created by Aleksandar Angelov on 3/17/19.
//  Copyright © 2019 Milen. All rights reserved.
//

import Foundation

enum RepositoryResult<ResultType> {
    case success(ResultType)
    case error(Error)
}

enum RepositoryError: Error, LocalizedError {
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
