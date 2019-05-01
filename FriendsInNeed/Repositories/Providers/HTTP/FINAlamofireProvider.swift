//
//  AlamofireProvider.swift
//  Help A Paw
//
//  Created by Aleksandar Angelov on 3/22/19.
//  Copyright © 2019 Milen. All rights reserved.
//

import Foundation
import Alamofire

class FINAlamofireProvider {
    
    func request(_ request: URLRequest, completionHandler: @escaping (RepositoryResult<[String : Any]>) -> Void) {
        Alamofire.request(request)
            .validate()
            .responseJSON(completionHandler: { (dataResponse: DataResponse<Any>) in
            switch dataResponse.result {
            case .failure(let error):
                completionHandler(.error(RepositoryError.network(reason: error.localizedDescription)))
            case .success(let value):
                guard let jsonDictionary = value as? [String: Any] else {
                    completionHandler(.error(RepositoryError.decoding))
                    return
                }
                completionHandler(.success(jsonDictionary))
            }
        })
    }
    
}
