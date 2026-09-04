//
//  XAuthClient.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2026/09/01.
//  Copyright © 2026 Tetsuya Nishikawa. All rights reserved.
//

import Foundation
import AppAuth
import RxSwift

protocol BaseXAuthClient: AnyObject {
    func authorize(presenter: AuthorizationSheetPresenter, completion: @escaping ((Bool) -> Void))
    func executeAuthorizedRequest(urlRequest: URLRequest) -> Observable<Result<Data, ApiError>>
    func resumeAuthorization(with url: URL) -> Bool
    func revokeSession() -> Observable<Bool>
    func discardSession()
    func hasAuthorizedSession() -> Bool
}

//NSObjectを継承しているのは、認証状態の変化を受け取る OIDAuthStateChangeDelegate が
//Objective-C のプロトコルのため
class XAuthClient: NSObject, BaseXAuthClient {
    static let shared = XAuthClient()

    private let authorizationPageUrl = "https://x.com/i/oauth2/authorize"
    private let tokenApiUrl = "https://api.x.com/2/oauth2/token"
    private let authStateKey = "x_auth_state"

    //Xが独自に決めた文字列で、標準にもAppAuthにも定義が無いため、
    //何を求めているのかをこちらの言葉で名付けている
    enum Scope: String, CaseIterable {
        case readTweets = "tweet.read"
        case postTweets = "tweet.write"
        case readAccount = "users.read"
        //外すとリフレッシュトークンが発行されず、アクセストークンの
        //寿命ごとに認可画面へ戻ることになる
        case keepAuthorized = "offline.access"
    }

    private let apiClient: BaseApiClient
    private let keychainConnector: BaseKeychainConnector
    private let plistConnector: BasePlistConnector

    private var authState: OIDAuthState?
    //提示中の認可手続きを保持しないのは、解放された時点で
    //コールバックの届け先が無くなり、認可画面から戻れなくなるため
    private var authorizationFlow: OIDExternalUserAgentSession?

    //private init にしていないのは、テストが Keychain と ApiClient を差し替えるため
    init(apiClient: BaseApiClient = ApiClient.shared,
         keychainConnector: BaseKeychainConnector = KeychainConnector.shared,
         plistConnector: BasePlistConnector = PlistConnector.shared) {
        self.apiClient = apiClient
        self.keychainConnector = keychainConnector
        self.plistConnector = plistConnector
        super.init()
        self.hold(authState: self.readAuthState())
    }

    func authorize(presenter: AuthorizationSheetPresenter,
                   completion: @escaping ((Bool) -> Void)) {
        guard let authorizationRequest = self.createAuthorizationRequest() else {
            completion(false)
            return
        }
        //始める前に前の手続きを畳むのは、後から届いた古いコールバックが
        //新しい手続きへの参照を消してしまうため
        self.authorizationFlow?.cancel()
        self.authorizationFlow = OIDAuthState
            .authState(byPresenting: authorizationRequest,
                       presenting: presenter.viewControllerForAuthorizationSheet) { [weak self] authState, _ in
                        self?.authorizationFlow = nil
                        guard let authState = authState else {
                            completion(false)
                            return
                        }
                        self?.hold(authState: authState)
                        self?.saveAuthState(authState)
                        completion(true)
        }
    }

    func executeAuthorizedRequest(urlRequest: URLRequest) -> Observable<Result<Data, ApiError>> {
        return self.executeWithFreshToken(urlRequest: urlRequest)
            .flatMap { [weak self] result -> Observable<Result<Data, ApiError>> in
                //401 のときだけ入れ直すのは、期限内であっても X 側で失効させられた
                //アクセストークンは、期限の判定だけでは捨てられないため
                guard case .failure(.unauthorized) = result,
                    let self = self else {
                        return Observable<Result<Data, ApiError>>.just(result)
                }
                self.authState?.setNeedsTokenRefresh()
                return self.executeWithFreshToken(urlRequest: urlRequest)
        }
    }

    //認可画面からの戻りをOS経由で受け取ったときの入口。
    //ASWebAuthenticationSessionは自分のコールバックへ直接返すため通常は通らないが、
    //Info.plistにスキームを登録している以上、届いたときの受け手が要る
    func resumeAuthorization(with url: URL) -> Bool {
        guard let authorizationFlow = self.authorizationFlow else { return false }
        do {
            try authorizationFlow.resumeExternalUserAgentFlow(url)
            self.authorizationFlow = nil
            return true
        } catch {
            //認可の戻りではないURLも同じ入口へ来るため、扱えないことは異常ではない
            return false
        }
    }

    func revokeSession() -> Observable<Bool> {
        guard let urlRequest = self.createRevokeTokenRequest() else {
            self.discardSession()
            return Observable<Bool>.just(false)
        }
        return self.apiClient
            .execute(urlRequest: urlRequest)
            .map { [weak self] result in
                //失効の成否に関わらず端末側を捨てるのは、X へ届かなかったときに
                //ログイン状態へ戻すと、使えないトークンを抱えたまま
                //ログアウトできなくなるため
                self?.discardSession()
                guard case .success = result else { return false }
                return true
        }
    }

    func discardSession() {
        self.authState = nil
        self.keychainConnector.deleteRecord(forKey: authStateKey)
    }

    func hasAuthorizedSession() -> Bool {
        return self.authState?.isAuthorized ?? false
    }

    private func executeWithFreshToken(urlRequest: URLRequest) -> Observable<Result<Data, ApiError>> {
        return self.getFreshAccessToken()
            .flatMap { [weak self] accessToken -> Observable<Result<Data, ApiError>> in
                guard let self = self, let accessToken = accessToken else {
                    return Observable<Result<Data, ApiError>>.just(.failure(.unauthorized))
                }
                return self.apiClient
                    .execute(urlRequest: urlRequest.adding(header: "Bearer " + accessToken,
                                                           forField: "Authorization"))
        }
    }

    private func getFreshAccessToken() -> Observable<String?> {
        return Observable<String?>.create { [weak self] observer in
            guard let authState = self?.authState else {
                observer.onNext(nil)
                observer.onCompleted()
                return Disposables.create()
            }
            authState.performAction { accessToken, _, _ in
                observer.onNext(accessToken)
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }

    //privateにしていないのは、認可画面へ渡すURLがXへ登録した値と一致することを
    //テストで確かめるため。ここがずれると、認可画面から戻れないことが実機で初めて分かる
    func createAuthorizationRequest() -> OIDAuthorizationRequest? {
        guard let configuration = self.createServiceConfiguration(),
            let clientId = self.plistConnector.getClientId(),
            let callbackUrl = self.createCallbackUrl() else { return nil }
        return OIDAuthorizationRequest(configuration: configuration,
                                       clientId: clientId,
                                       scopes: Scope.allCases.map { $0.rawValue },
                                       redirectURL: callbackUrl,
                                       responseType: OIDResponseTypeCode,
                                       additionalParameters: nil)
    }

    //エンドポイントを直接指定しているのは、X が OpenID Connect の
    //ディスカバリ文書を公開しておらず、取得しに行く先が無いため
    private func createServiceConfiguration() -> OIDServiceConfiguration? {
        guard let authorizationEndpoint = URL(string: authorizationPageUrl),
            let tokenEndpoint = URL(string: tokenApiUrl) else { return nil }
        return OIDServiceConfiguration(authorizationEndpoint: authorizationEndpoint,
                                       tokenEndpoint: tokenEndpoint)
    }

    //Swift 側に文字列を持たず Info.plist から読むのは、認可で使う戻り先と
    //端末に登録されたスキームがずれると、認可画面から帰る先を失うため
    private func createCallbackUrl() -> URL? {
        guard let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]],
            let schemes = urlTypes.first?["CFBundleURLSchemes"] as? [String],
            let scheme = schemes.first else { return nil }
        return URL(string: scheme + "://callback")
    }

    private func createRevokeTokenRequest() -> URLRequest? {
        guard let clientId = self.plistConnector.getClientId() else { return nil }
        //リフレッシュトークンを優先して渡すのは、RFC 7009 が同じ認可から出た
        //アクセストークンも無効にすべきと定める一方、逆向きの定めが無いため
        if let refreshToken = self.authState?.refreshToken {
            return V2ApiRequestFactory.shared.createRevokeTokenRequest(token: refreshToken,
                                                                      tokenTypeHint: "refresh_token",
                                                                      clientId: clientId)
        }
        guard let accessToken = self.authState?.lastTokenResponse?.accessToken else { return nil }
        return V2ApiRequestFactory.shared.createRevokeTokenRequest(token: accessToken,
                                                                  tokenTypeHint: "access_token",
                                                                  clientId: clientId)
    }

    private func hold(authState: OIDAuthState?) {
        self.authState = authState
        authState?.stateChangeDelegate = self
        authState?.errorDelegate = self
    }

    private func readAuthState() -> OIDAuthState? {
        guard let archived = self.keychainConnector.getData(withKey: authStateKey) else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: OIDAuthState.self, from: archived)
    }

    private func saveAuthState(_ authState: OIDAuthState) {
        guard let archived = try? NSKeyedArchiver.archivedData(withRootObject: authState,
                                                              requiringSecureCoding: true) else { return }
        _ = self.keychainConnector.registerData(key: authStateKey, value: archived)
    }
}

//X はリフレッシュのたびにトークンをローテーションするため、
//変化を保存し損ねると、次の起動で使えないトークンだけが残る
extension XAuthClient: OIDAuthStateChangeDelegate {
    func didChange(_ state: OIDAuthState) {
        self.saveAuthState(state)
    }
}

//認可そのものが壊れたときに呼ばれる。通信の一時的な不調とは別で、
//この認証状態は以後どう使っても通らないため、持ち主の側で捨てる
extension XAuthClient: OIDAuthStateErrorDelegate {
    func authState(_ state: OIDAuthState, didEncounterAuthorizationError error: Error) {
        self.discardSession()
    }
}
