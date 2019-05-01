//
//  AlamofireBaseRouter.swift
//  Help A Paw
//
//  Created by Aleksandar Angelov on 3/22/19.
//  Copyright © 2019 Milen. All rights reserved.
//

import Foundation
import Alamofire

protocol FINAlamofireBaseRouter {
    
    var httpMethod: Alamofire.HTTPMethod { get }
    var encoding: Alamofire.ParameterEncoding? { get }
    var path: String { get }
    var parameters: [String: Any] { get }
    var baseUrl: String { get }
    
}
