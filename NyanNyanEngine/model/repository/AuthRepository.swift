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
    func getRequestToken() -> Observable<URL>
    func downloadAccessToken(redirectedUrl: URL) -> Observable<Bool>
}

class AuthRepository: BaseAuthRepository {
    static let shared = AuthRepository()
    
    private let apiClient: BaseApiClient
    
    private init(apiClient: BaseApiClient = ApiClient.shared) {
        self.apiClient = apiClient
    }
    
    func getRequestToken() -> Observable<URL> {
        guard let apiKey = PlistConnector.shared.getString(withKey: "apiKey"),
            let apiSecret = PlistConnector.shared.getString(withKey: "apiSecret"),
            let urlRequest = ApiRequestFactory(apiKey: apiKey, apiSecret: apiSecret, oauthTimeStamp: "1556750456", oauthNonce: "0000").createRequestTokenRequest() else { return Observable<URL>.empty() }
        return self.apiClient
            .postResponse(urlRequest: urlRequest)
            .map { [unowned self] in self.toAuthTokenValue(data: $0) }
            .flatMap { $0.flatMap {Observable<URL>.just($0)} ?? Observable<URL>.empty() }
    }
    
    func downloadAccessToken(redirectedUrl: URL) -> Observable<Bool> {
        guard let urlRequest = ApiRequestFactory().createAccessTokenRequest(redirectedUrl: redirectedUrl) else { return Observable<Bool>.empty() }
        return self.apiClient
            .postResponse(urlRequest: urlRequest)
            .map { [unowned self] in
                print(String(data: $0!, encoding: .utf8))
            }
            .map { false }
    }
    
    private func toAuthTokenValue(data: Data?) -> URL? {
        guard let d = data,
            let str = String(data: d, encoding: .utf8) else { return nil }
            return URL(string: "https://api.twitter.com/oauth/authenticate?" + str)
    }
}
