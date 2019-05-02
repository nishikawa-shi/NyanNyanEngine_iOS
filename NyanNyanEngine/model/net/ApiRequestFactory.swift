//
//  RequestTokenUrlRequestFactory.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/05/02.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation

protocol BaseApiRequestFactory: AnyObject {
    func createRequestTokenRequest() -> URLRequest?
}

class ApiRequestFactory: BaseApiRequestFactory {
    func createRequestTokenRequest() -> URLRequest? {
        guard let urlObj = URL(string: "https://nyannyanengine-ios-d.firebaseapp.com/oauth/request_token") else { return nil }
        var urlRequest = URLRequest(url: urlObj,
                                    cachePolicy: .reloadIgnoringLocalCacheData,
                                    timeoutInterval: 5)
        urlRequest.httpMethod = "POST"
        let headers: [String: String]? = ["nyan": "nyaan"]
        if let heads = headers {
            heads.forEach {
                urlRequest.addValue($0.value, forHTTPHeaderField: $0.key)
            }
        }
        
        return urlRequest
    }
}
