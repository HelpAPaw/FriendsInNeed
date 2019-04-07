//
//  AlamofireProvider.swift
//  Help A Paw
//
//  Created by Aleksandar Angelov on 3/22/19.
//  Copyright © 2019 Milen. All rights reserved.
//

import Foundation
import Alamofire

class AlamofireProvider: HTTPProvider {
    
    func request(_ request: URLRequest, completionHandler: @escaping (RepositoryResult<[String : Any]>) -> Void) {
        Alamofire.request(request).validate().responseJSON(completionHandler: { (dataResponse: DataResponse<Any>) in
            switch dataResponse.result {
            case .failure(let error):
                completionHandler(.error(HTTPError.network(reason: error.localizedDescription)))
            case .success(let value):
                guard let jsonDictionary = value as? [String: Any] else {
                    completionHandler(.error(HTTPError.decoding))
                    return
                }
                completionHandler(.success(jsonDictionary))
            }
        })
    }
    
}
