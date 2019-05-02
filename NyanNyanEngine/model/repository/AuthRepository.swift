//
//  AuthRepository.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/05/02.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation
import RxSwift

protocol BaseAuthRepository: AnyObject {
    func getRequestToken() -> Observable<String?>
}

class AuthRepository: BaseAuthRepository {
    static let shared = AuthRepository()
    
    private let apiClient: BaseApiClient
    
    private init(apiClient: BaseApiClient = ApiClient.shared) {
        self.apiClient = apiClient
    }
    
    func getRequestToken() -> Observable<String?> {
        guard let urlRequest = ApiRequestFactory().createRequestTokenRequest() else { return Observable<String?>.empty() }
        return self.apiClient
            .postResponse(urlRequest: urlRequest)
            .map { [unowned self] in self.toAuthTokenValue(data: $0) }
    }
    
    private func toAuthTokenValue(data: Data?) -> String? {
        guard let d = data,
            let str = String(data: d, encoding: .utf8),
            let comp = NSURLComponents(string: "https://example.com/?" + str),
            let queryItems = comp.queryItems as [NSURLQueryItem]? else { return nil }
        
        return queryItems.filter { item in
            return item.name == "oauth_token"
            }.first?.value
    }
}
