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
