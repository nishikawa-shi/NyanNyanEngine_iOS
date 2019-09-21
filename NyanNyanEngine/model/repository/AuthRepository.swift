//
//  AuthRepository.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/05/02.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

protocol BaseAuthRepository: AnyObject {
    func downloadAccessToken(redirectedUrl: URL,
                             modelUpdateLogic: @escaping(() -> Void) ) -> Observable<Bool>
    func invalidateAccessToken(modelUpdateLogic: @escaping(() -> Void) ) -> Observable<Bool>
    
    func getRequestToken()
    func getLoggedInStatus() -> Bool
    
    var currentUser: Observable<String> { get }
    var isLoggedIn: Observable<Bool>? { get }
    var authPageUrl: Observable<URL?>? { get }
    
    var loginExecutedAt: AnyObserver<String>? { get }
}

class AuthRepository: BaseAuthRepository {
    static let shared = AuthRepository()
    
    private let disposeBag = DisposeBag()
    private let apiClient: BaseApiClient
    private let userDefaultsConnector: BaseUserDefaultsConnector
    
    let currentUser: Observable<String>
    var isLoggedIn: Observable<Bool>? = nil
    private let _isLoggedIn: BehaviorRelay<Bool>
    var authPageUrl: Observable<URL?>? = nil
    private let _authPageUrl: BehaviorRelay<URL?>
    
    var loginExecutedAt: AnyObserver<String>? = nil
    
    private init(apiClient: BaseApiClient = ApiClient.shared,
                 userDefaultsConnector: BaseUserDefaultsConnector = UserDefaultsConnector.shared) {
        self.apiClient = apiClient
        self.userDefaultsConnector = userDefaultsConnector
        
        let _currentUser = BehaviorRelay<String>(value: "にゃんにゃんエンジン")
        self.currentUser = _currentUser.asObservable()
        
        //本当はself.getLoggedInStatusを呼びたいのだが、selfを使うものが、loginExecutedAtとここと、2箇所あ
        //またこのためだけに全プロパティをvarにするのもキモいので、getLoggedInStatusnの中身を直書きしている。
        self._isLoggedIn = BehaviorRelay<Bool>(value: (userDefaultsConnector.getString(withKey: "screen_name") != nil))
        self.isLoggedIn = _isLoggedIn.asObservable()
        
        self._authPageUrl = BehaviorRelay<URL?>(value: nil)
        self.authPageUrl = _authPageUrl.asObservable()
        
        self.loginExecutedAt = AnyObserver<String> { [unowned self] executedAt in
            self.getCurrentUser()
                .bind(to: _currentUser)
                .disposed(by: self.disposeBag)
        }
    }
    
    func getRequestToken() {
        guard let apiKey = PlistConnector.shared.getApiKey(),
            let apiSecret = PlistConnector.shared.getApiSecret(),
            let urlRequest = ApiRequestFactory(apiKey: apiKey,
                                               apiSecret: apiSecret,
                                               oauthNonce: "0000").createRequestTokenRequest() else { return }
        self.apiClient
            .executeHttpRequest(urlRequest: urlRequest)
            .map { [unowned self] in self.toAuthTokenValue(data: $0) }
            .flatMap { $0.flatMap {Observable<URL>.just($0)} ?? Observable<URL>.empty() }
            .subscribe { [unowned self] in self._authPageUrl.accept($0.element) }
            .disposed(by: self.disposeBag)
    }
    
    func invalidateAccessToken(modelUpdateLogic: @escaping (() -> Void)) -> Observable<Bool> {
            guard let apiKey = PlistConnector.shared.getApiKey(),
            let apiSecret = PlistConnector.shared.getApiSecret(),
            let accessToken = UserDefaultsConnector.shared.getString(withKey: "oauth_token"),
            let accessTokenSecret = UserDefaultsConnector.shared.getString(withKey: "oauth_token_secret"),
            let urlRequest = ApiRequestFactory(apiKey: apiKey,
                                               apiSecret: apiSecret,
                                               oauthNonce: "0000",
                                               accessTokenSecret: accessTokenSecret,
                                               accessToken: accessToken).createInvalidateTokenRequest() else {
                                                modelUpdateLogic()
                                                return Observable<Bool>.empty()
        }
        //TODO: ローカルのアクセストークン情報を削除し、もらったクロージャをもとにモデルをアップデートする処理。
        return self.apiClient
            .executeHttpRequest(urlRequest: urlRequest)
            .map { [unowned self] _ in self.deleteTokens() }
            .map { true }
    }
    
    func downloadAccessToken(redirectedUrl: URL,
                             modelUpdateLogic: @escaping (() -> Void)) -> Observable<Bool> {
        guard let urlRequest = ApiRequestFactory().createAccessTokenRequest(redirectedUrl: redirectedUrl) else { return Observable<Bool>.empty() }
        return self.apiClient
            .executeHttpRequest(urlRequest: urlRequest)
            .map { [unowned self] in self.parseTokens(accessTokenApiResponse: $0) }
            .map { [unowned self] in self.saveTokens(accessTokenApiResponseQuery: $0 ?? [])}
            .map { [unowned self] in self._isLoggedIn.accept(self.getLoggedInStatus()) }
            .map (modelUpdateLogic)
            .map { true }
    }
    
    func getLoggedInStatus() -> Bool {
        return self.userDefaultsConnector.getString(withKey: "screen_name") != nil
    }
    
    private func getCurrentUser() -> Observable<String> {
        let currentUser = userDefaultsConnector.getString(withKey: "screen_name") ?? R.string.stringValues.default_timeline_name()
        return Observable<String>.create { observer in
            observer.onNext(currentUser)
            return Disposables.create()
        }
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
        accessTokenApiResponseQuery.forEach { [unowned self] item in
            print(item)
            guard let value = item.value else { return }
            self.userDefaultsConnector.registerString(key: item.name, value: value)
        }
    }
    
    private func deleteTokens() {
        let accountKeys = [
            "oauth_token",
            "oauth_token_secret",
            "user_id",
            "screen_name",
        ]
        accountKeys.forEach { [unowned self] key in
            self.userDefaultsConnector.deleteRecord(forKey: key)
        }
        print("delete token completed")
    }
}
