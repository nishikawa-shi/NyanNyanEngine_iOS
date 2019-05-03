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
    private let userDefaultsConnector: BaseUserDefaultsConnector
    
    private init(apiClient: BaseApiClient = ApiClient.shared,
                 userDefaultsConnector: BaseUserDefaultsConnector = UserDefaultsConnector.shared) {
        self.apiClient = apiClient
        self.userDefaultsConnector = userDefaultsConnector
    }
    
    func getRequestToken() -> Observable<URL> {
        guard let apiKey = PlistConnector.shared.getString(withKey: "apiKey"),
            let apiSecret = PlistConnector.shared.getString(withKey: "apiSecret"),
            let urlRequest = ApiRequestFactory(apiKey: apiKey,
                                               apiSecret: apiSecret,
                                               oauthTimeStamp: String(Int(NSDate().timeIntervalSince1970)),
                                               oauthNonce: "0000").createRequestTokenRequest() else { return Observable<URL>.empty() }
        return self.apiClient
            .postResponse(urlRequest: urlRequest)
            .map { [unowned self] in self.toAuthTokenValue(data: $0) }
            .flatMap { $0.flatMap {Observable<URL>.just($0)} ?? Observable<URL>.empty() }
    }
    
    func downloadAccessToken(redirectedUrl: URL) -> Observable<Bool> {
        guard let urlRequest = ApiRequestFactory().createAccessTokenRequest(redirectedUrl: redirectedUrl) else { return Observable<Bool>.empty() }
        return self.apiClient
            .postResponse(urlRequest: urlRequest)
            .map { [unowned self] in self.parseTokens(accessTokenApiResponse: $0) }
            .map { [unowned self] in self.saveTokens(accessTokenApiResponseQuery: $0 ?? [])}
            .map { true }
    }
    
    private func toAuthTokenValue(data: Data?) -> URL? {
        guard let d = data,
            let str = String(data: d, encoding: .utf8) else { return nil }
        return URL(string: "https://api.twitter.com/oauth/authorize?" + str)
    }
    
    private func parseTokens(accessTokenApiResponse: Data?) -> [URLQueryItem]? {
        guard let d = accessTokenApiResponse,
            let str = String(data: d, encoding: .utf8) else { return nil }
        return  NSURLComponents(string: "https://nyannyanengine.firebaseapp.com/tekitou?" + str)?.queryItems
    }
    
    private func saveTokens(accessTokenApiResponseQuery: [URLQueryItem]) {
        accessTokenApiResponseQuery.forEach { item in
            print(item)
            guard let value = item.value else { return }
            self.userDefaultsConnector.registerString(key: item.name, value: value)
        }
    }
}
