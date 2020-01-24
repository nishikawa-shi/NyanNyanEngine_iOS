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
    func invalidateAccountInfo(modelUpdateLogic: @escaping(() -> Void) ) -> Observable<Bool>
    
    func getRequestToken()
    func getLoggedInStatus() -> Bool
    
    var currentAccount: Observable<Account> { get }
    var isLoggedIn: Observable<Bool>? { get }
    var logoutSucceeded: Observable<Bool>? { get }
    var authPageUrl: Observable<URL?>? { get }
    
    var accountUpdatedAt: AnyObserver<String>? { get }
}

class AuthRepository: BaseAuthRepository {
    static let shared = AuthRepository()
    
    private let disposeBag = DisposeBag()
    private let apiClient: BaseApiClient
    private let userDefaultsConnector: BaseUserDefaultsConnector
    
    let currentAccount: Observable<Account>
    var isLoggedIn: Observable<Bool>? = nil
    private let _isLoggedIn: BehaviorRelay<Bool>
    var logoutSucceeded: Observable<Bool>? = nil
    private let _logoutSucceeded: PublishRelay<Bool>
    var authPageUrl: Observable<URL?>? = nil
    private let _authPageUrl: BehaviorRelay<URL?>
    
    var accountUpdatedAt: AnyObserver<String>? = nil
    
    private init(apiClient: BaseApiClient = ApiClient.shared,
                 userDefaultsConnector: BaseUserDefaultsConnector = UserDefaultsConnector.shared) {
        self.apiClient = apiClient
        self.userDefaultsConnector = userDefaultsConnector
        
        let _currentAccount = BehaviorRelay<Account>(value: Account())
        self.currentAccount = _currentAccount.asObservable()
        
        //本当はself.getLoggedInStatusを呼びたいのだが、selfを使うものが、loginExecutedAtとここと、2箇所あ
        //またこのためだけに全プロパティをvarにするのもキモいので、getLoggedInStatusnの中身を直書きしている。
        self._isLoggedIn = BehaviorRelay<Bool>(value: (userDefaultsConnector.getString(withKey: "screen_name") != nil))
        self.isLoggedIn = _isLoggedIn.asObservable()
        
        self._logoutSucceeded = PublishRelay<Bool>()
        self.logoutSucceeded = _logoutSucceeded.asObservable()
        
        self._authPageUrl = BehaviorRelay<URL?>(value: nil)
        self.authPageUrl = _authPageUrl.asObservable()
        
        self.accountUpdatedAt = AnyObserver<String> { [unowned self] executedAt in
            self.getCurrentAccount()
                .bind(to: _currentAccount)
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
    
    func invalidateAccountInfo(modelUpdateLogic: @escaping (() -> Void)) -> Observable<Bool> {
        guard let apiKey = PlistConnector.shared.getApiKey(),
            let apiSecret = PlistConnector.shared.getApiSecret(),
            let accessToken = UserDefaultsConnector.shared.getString(withKey: "oauth_token"),
            let accessTokenSecret = UserDefaultsConnector.shared.getString(withKey: "oauth_token_secret"),
            let urlRequest = ApiRequestFactory(apiKey: apiKey,
                                               apiSecret: apiSecret,
                                               oauthNonce: "0000",
                                               accessTokenSecret: accessTokenSecret,
                                               accessToken: accessToken).createInvalidateTokenRequest() else {
                                                self._logoutSucceeded.accept(false)
                                                modelUpdateLogic()
                                                return Observable<Bool>.empty()
        }
        return self.apiClient
            .executeHttpRequest(urlRequest: urlRequest)
            .map { [unowned self] _ in self.deleteAccountInfo() }
            .map { [unowned self] in
                self._isLoggedIn.accept(self.getLoggedInStatus())
                self._logoutSucceeded.accept(true) }
            .map (modelUpdateLogic)
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
            .map { [unowned self] in self.downloadUserInfo() }
            .map (modelUpdateLogic)
            .map { true }
    }
    
    func downloadUserInfo() {
        guard let apiKey = PlistConnector.shared.getApiKey(),
            let apiSecret = PlistConnector.shared.getApiSecret(),
            let accessToken = UserDefaultsConnector.shared.getString(withKey: "oauth_token"),
            let accessTokenSecret = UserDefaultsConnector.shared.getString(withKey: "oauth_token_secret"),
            let urlRequest = ApiRequestFactory(apiKey: apiKey,
                                               apiSecret: apiSecret,
                                               oauthNonce: "0000",
                                               accessTokenSecret: accessTokenSecret,
                                               accessToken: accessToken).createVerifyCredentialsRequest() else { return }
        self.apiClient.executeHttpRequest(urlRequest: urlRequest)
            .map { [unowned self] in self.saveUserInfo(user: self.toUser(data: $0))}
            .map { [unowned self] in self.accountUpdatedAt?.onNext("8888/12/31 23:59:59") }
            .subscribe()
            .disposed(by: disposeBag)
    }
    
    func getLoggedInStatus() -> Bool {
        return self.userDefaultsConnector.getString(withKey: "screen_name") != nil
    }
    
    private func getCurrentAccount() -> Observable<Account> {
        let defaultUser = User(name: R.string.stringValues.default_user_name(),
                               screenName: R.string.stringValues.default_user_id(),
                               profileImageUrlHttps: R.string.stringValues.default_user_profile_url())
        let defaultObservable = Observable<Account>.create {
            $0.onNext(Account(user: defaultUser,
                              headerName: R.string.stringValues.default_timeline_name()))
            return Disposables.create()
        }
        
        if !self.getLoggedInStatus() {
            return defaultObservable
        }
        if !isAllAccountInfoFetched() {
            self.downloadUserInfo()
        }
        guard let screenName = userDefaultsConnector.getString(withKey: "screen_name"),
            let headerName = userDefaultsConnector.getString(withKey: "screen_name"),
            let name = userDefaultsConnector.getString(withKey: "name"),
            let profileImageUrlHttps = userDefaultsConnector.getString(withKey: "profile_image_url_https") else {
                return defaultObservable
        }
        let user = User(name: name, screenName: screenName, profileImageUrlHttps: profileImageUrlHttps)
        let account = Account(user: user, headerName: headerName)
        return Observable<Account>.create { observer in
            observer.onNext(account)
            return Disposables.create()
        }
    }
    
    private func isAllAccountInfoFetched() -> Bool {
        let requiredKeys = ["screen_name",
                            "name",
                            "profile_image_url_https"]
        return requiredKeys.reduce(true) { [unowned self] (current: Bool, additive: String) -> Bool in
            return current && (self.userDefaultsConnector.getString(withKey: additive) != nil)
        }
    }
    
    private func toUser(data: Data?) -> User? {
        let decorder = JSONDecoder()
        decorder.keyDecodingStrategy = .convertFromSnakeCase
        guard let d = data else { return nil }
        return try? decorder.decode(User.self, from: d)
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
    
    private func saveUserInfo(user: User?) {
        guard let name = user?.name,
            let profileImageUrlHttps = user?.profileImageUrlHttps else { return }
        let records = ["name": name,
                       "profile_image_url_https": profileImageUrlHttps]
        records.forEach { [unowned self] in
            self.userDefaultsConnector.registerString(key: $0.key, value: $0.value)
        }
    }
    
    private func deleteAccountInfo() {
        let accountKeys = [
            "oauth_token",
            "oauth_token_secret",
            "user_id",
            "screen_name",
            "name",
            "profile_image_url_https"
        ]
        accountKeys.forEach { [unowned self] key in
            self.userDefaultsConnector.deleteRecord(forKey: key)
        }
        print("delete token completed")
    }
}
