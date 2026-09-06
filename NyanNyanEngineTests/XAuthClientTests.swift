//
//  XAuthClientTests.swift
//  NyanNyanEngineTests
//
//  Created by Tetsuya Nishikawa on 2026/09/01.
//  Copyright © 2026 Tetsuya Nishikawa. All rights reserved.
//

import XCTest
import UIKit
import AppAuth
import RxSwift
@testable import NyanNyanEngine

class XAuthClientTests: XCTestCase {

    private var keychainConnector: StubKeychainConnector!
    private var apiClient: StubApiClient!
    private var disposeBag = DisposeBag()
    private let authStateKey = "x_auth_state"
    private let clientId = "nyannyan-client-id"

    override func setUp() {
        super.setUp()
        keychainConnector = StubKeychainConnector()
        apiClient = StubApiClient()
        disposeBag = DisposeBag()

        //AppAuthはトークンの更新を自前のURLSessionで飛ばすため、ApiClientを
        //差し替えるだけではXへ出ていく経路が残る。ここで塞いでおく
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [BlockedUrlProtocol.self]
        OIDURLSessionProvider.setSession(URLSession(configuration: configuration))
    }

    override func tearDown() {
        OIDURLSessionProvider.setSession(URLSession.shared)
        super.tearDown()
    }

    func testHasNoSessionBeforeLogin() {
        XCTAssertFalse(createService().hasAuthorizedSession())
    }

    //アプリを終了してもログインが続くことは、Keychainへ保存した認証状態を
    //読み戻せることに乗っている
    func testRestoresSessionSavedInKeychain() {
        keychainConnector.records[authStateKey] = archived(authState: createAuthState())

        XCTAssertTrue(createService().hasAuthorizedSession())
    }

    func testIgnoresBrokenRecordInsteadOfCrashing() {
        keychainConnector.records[authStateKey] = Data("認証状態ではないもの".utf8)

        XCTAssertFalse(createService().hasAuthorizedSession())
    }

    func testDiscardedSessionLeavesNothingBehind() {
        keychainConnector.records[authStateKey] = archived(authState: createAuthState())
        let service = createService()

        service.discardSession()

        XCTAssertFalse(service.hasAuthorizedSession())
        XCTAssertNil(keychainConnector.records[authStateKey])
    }

    func testAuthorizedRequestCarriesBearerToken() {
        keychainConnector.records[authStateKey] = archived(authState: createAuthState(accessToken: "あくせすとーくん"))
        apiClient.result = .success(Data("にゃーん".utf8))
        let service = createService()
        let expectation = self.expectation(description: "リクエストが実行される")

        service.executeAuthorizedRequest(urlRequest: URLRequest(url: URL(string: "https://api.x.com/2/users/me")!))
            .subscribe(onNext: { _ in expectation.fulfill() })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 5)

        XCTAssertEqual(apiClient.executedRequests.first?.value(forHTTPHeaderField: "Authorization"),
                       "Bearer あくせすとーくん")
    }

    //ログインしていない状態で実行しても、トークン無しのリクエストを
    //Xへ投げない（課金の対象になる呼び出しを増やさない）
    func testRefusesRequestWhenNotLoggedIn() {
        let service = createService()
        let expectation = self.expectation(description: "結果が返る")
        var received: Result<Data, ApiError>? = nil

        service.executeAuthorizedRequest(urlRequest: URLRequest(url: URL(string: "https://api.x.com/2/users/me")!))
            .subscribe(onNext: {
                received = $0
                expectation.fulfill()
            })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 5)

        XCTAssertEqual(received, .failure(.unauthorized))
        XCTAssertTrue(apiClient.executedRequests.isEmpty)
    }

    //アクセストークンではなくリフレッシュトークンを渡す。RFC 7009 は同じ認可から
    //出たアクセストークンも無効にすべきと定める一方、逆向きの定めが無い
    func testRevokeSendsRefreshTokenToX() {
        keychainConnector.records[authStateKey] = archived(authState: createAuthState(refreshToken: "りふれっしゅ"))
        apiClient.result = .success(Data())
        let service = createService()

        XCTAssertEqual(revoke(service: service), true)

        let request = apiClient.executedRequests.first
        let body = request?.httpBody.flatMap { String(data: $0, encoding: .utf8) }
        XCTAssertEqual(request?.url?.absoluteString, "https://api.x.com/2/oauth2/revoke")
        XCTAssertEqual(body?.contains("token_type_hint=refresh_token"), true)
        XCTAssertEqual(body?.contains("りふれっしゅ".addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""),
                       true)
    }

    //Xへ失効が届かなくても端末側は捨てる。ログイン状態へ戻すと、使えない
    //トークンを抱えたままログアウトできなくなる
    func testRevokeClearsSessionEvenWhenXRejectsIt() {
        keychainConnector.records[authStateKey] = archived(authState: createAuthState())
        apiClient.result = .failure(.serverError)
        let service = createService()

        XCTAssertEqual(revoke(service: service), false)

        XCTAssertFalse(service.hasAuthorizedSession())
        XCTAssertNil(keychainConnector.records[authStateKey])
    }

    func testRevokeClearsSessionWhenThereIsNothingToRevoke() {
        let service = createService()

        XCTAssertEqual(revoke(service: service), false)

        XCTAssertFalse(service.hasAuthorizedSession())
        XCTAssertTrue(apiClient.executedRequests.isEmpty)
    }

    //認可画面へ渡すURLは、Xのポータルへ登録した値と一致していないと弾かれる。
    //Debug構成のコールバックURIをここで固定しておく
    func testAuthorizationUrlMatchesWhatXExpects() {
        let request = createService().createAuthorizationRequest()
        let url = request?.authorizationRequestURL()
        let queries = URLComponents(string: url?.absoluteString ?? "")?.queryItems ?? []

        XCTAssertEqual(url?.host, "x.com")
        XCTAssertEqual(url?.path, "/i/oauth2/authorize")
        XCTAssertEqual(query(queries, "client_id"), "nyannyan-client-id")
        XCTAssertEqual(query(queries, "redirect_uri"), "com.ntetz.ios.nyannyanengine-d://callback")
        XCTAssertEqual(query(queries, "response_type"), "code")
        XCTAssertEqual(query(queries, "scope"), "tweet.read tweet.write users.read offline.access")
    }

    //PKCEとstateはAppAuthが用意する。自作しない判断（ADR 0002）が
    //実際に効いていることを確かめる
    func testAuthorizationUrlCarriesPkceAndState() {
        let request = createService().createAuthorizationRequest()
        let queries = URLComponents(string: request?.authorizationRequestURL().absoluteString ?? "")?.queryItems ?? []

        XCTAssertEqual(query(queries, "code_challenge_method"), "S256")
        XCTAssertFalse((query(queries, "code_challenge") ?? "").isEmpty)
        XCTAssertFalse((query(queries, "state") ?? "").isEmpty)
        XCTAssertNotNil(request?.codeVerifier)
    }

    //clientIdが無いままだと認可画面のURLを組み立てられない。落ちずに
    //「認可されなかった」として戻ることを確かめる
    func testAuthorizationEndsQuietlyWithoutClientId() {
        let service = createService(clientId: nil)
        let expectation = self.expectation(description: "結果が返る")
        var authorized = true

        service.authorize(presenter: StubAuthorizationSheetPresenter()) {
            authorized = $0
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5)

        XCTAssertFalse(authorized)
    }

    private func query(_ queries: [URLQueryItem], _ name: String) -> String? {
        return queries.first { $0.name == name }?.value
    }

    private func createService() -> XAuthClient {
        return createService(clientId: clientId)
    }

    private func createService(clientId: String?) -> XAuthClient {
        return XAuthClient(apiClient: apiClient,
                            keychainConnector: keychainConnector,
                            plistConnector: StubPlistConnector(clientId: clientId))
    }

    private func revoke(service: XAuthClient) -> Bool? {
        let expectation = self.expectation(description: "失効の結果が返る")
        var revoked: Bool? = nil

        service.revokeSession()
            .subscribe(onNext: {
                revoked = $0
                expectation.fulfill()
            })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 5)

        return revoked
    }

    private func archived(authState: OIDAuthState) -> Data {
        return try! NSKeyedArchiver.archivedData(withRootObject: authState, requiringSecureCoding: true)
    }

    //AppAuthの認証状態を手で組み立てているのは、認可画面を通さずに
    //「ログイン済みの端末」を再現するため
    private func createAuthState(accessToken: String = "あくせす",
                                 refreshToken: String = "りふれっしゅ") -> OIDAuthState {
        let configuration = OIDServiceConfiguration(
            authorizationEndpoint: URL(string: "https://x.com/i/oauth2/authorize")!,
            tokenEndpoint: URL(string: "https://api.x.com/2/oauth2/token")!)
        let callbackUrl = URL(string: "com.ntetz.ios.nyannyanengine-d://callback")!
        let authorizationRequest = OIDAuthorizationRequest(configuration: configuration,
                                                          clientId: clientId,
                                                          scopes: ["tweet.read"],
                                                          redirectURL: callbackUrl,
                                                          responseType: OIDResponseTypeCode,
                                                          additionalParameters: nil)
        let authorizationResponse = OIDAuthorizationResponse(
            request: authorizationRequest,
            parameters: ["code": "にゃんこーど" as NSString,
                         "state": (authorizationRequest.state ?? "") as NSString])
        let tokenRequest = OIDTokenRequest(configuration: configuration,
                                          grantType: OIDGrantTypeAuthorizationCode,
                                          authorizationCode: "にゃんこーど",
                                          redirectURL: callbackUrl,
                                          clientID: clientId,
                                          clientSecret: nil,
                                          scopes: ["tweet.read"],
                                          refreshToken: nil,
                                          codeVerifier: authorizationRequest.codeVerifier,
                                          additionalParameters: nil)
        let tokenResponse = OIDTokenResponse(
            request: tokenRequest,
            parameters: ["access_token": accessToken as NSString,
                         "refresh_token": refreshToken as NSString,
                         "token_type": "bearer" as NSString,
                         "expires_in": NSNumber(value: 7200)])
        return OIDAuthState(authorizationResponse: authorizationResponse, tokenResponse: tokenResponse)
    }
}

//AppAuthが通信しようとしたら、黙って成功させずにその場で失敗させる
private class BlockedUrlProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
    }

    override func stopLoading() { }
}

private class StubAuthorizationSheetPresenter: AuthorizationSheetPresenter {
    let viewControllerForAuthorizationSheet = UIViewController()
}

private class StubKeychainConnector: BaseKeychainConnector {
    var records: [String: Data] = [:]

    func registerData(key: String, value: Data) -> Bool {
        records[key] = value
        return true
    }

    func getData(withKey key: String) -> Data? {
        return records[key]
    }

    func deleteRecord(forKey key: String) {
        records.removeValue(forKey: key)
    }
}

private class StubPlistConnector: BasePlistConnector {
    private let clientId: String?

    init(clientId: String?) {
        self.clientId = clientId
    }

    func getClientId() -> String? {
        return clientId
    }

    func getString(withKey: String) -> String? {
        return nil
    }
}

private class StubApiClient: BaseApiClient {
    var result: Result<Data, ApiError> = .failure(.noResponse)
    var executedRequests: [URLRequest] = []

    func executeHttpRequest(urlRequest: URLRequest) -> Observable<Data?> {
        return execute(urlRequest: urlRequest).map { try? $0.get() }
    }

    func execute(urlRequest: URLRequest) -> Observable<Result<Data, ApiError>> {
        executedRequests.append(urlRequest)
        return Observable<Result<Data, ApiError>>.just(result)
    }
}
