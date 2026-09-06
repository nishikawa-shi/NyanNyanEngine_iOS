//
//  ApiClientTests.swift
//  NyanNyanEngineTests
//
//  Created by Tetsuya Nishikawa on 2026/09/01.
//  Copyright © 2026 Tetsuya Nishikawa. All rights reserved.
//

import XCTest
import RxSwift
@testable import NyanNyanEngine

class ApiClientTests: XCTestCase {

    private var apiClient: ApiClient!
    private var disposeBag = DisposeBag()
    private let requestUrl = URL(string: "https://api.x.com/2/users/me")!
    //待ち時間を短く切り詰めないのは、ここで測りたいのが応答の速さではなく
    //「応答が返ってくること」だけのため。締め切りを詰めても検証は強くならず、
    //実行環境が混み合ったときに、確かめたい内容と無関係な失敗が増える
    private let responseWaitLimit: TimeInterval = 30

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubUrlProtocol.self]
        apiClient = ApiClient(urlSession: URLSession(configuration: configuration))
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        StubUrlProtocol.stubbedStatusCode = nil
        StubUrlProtocol.stubbedBody = Data()
        super.tearDown()
    }

    func testReturnsBodyWhenXAnswersOk() {
        StubUrlProtocol.stubbedBody = Data("にゃーん".utf8)

        XCTAssertEqual(execute(statusCode: 200), .success(Data("にゃーん".utf8)))
    }

    //投稿の成否がここに乗っている。201を失敗として扱うと、実際には
    //飛んでいるツイートがエラー扱いになる
    func testTreats201AsSuccess() {
        StubUrlProtocol.stubbedBody = Data("にゃーん".utf8)

        XCTAssertEqual(execute(statusCode: 201), .success(Data("にゃーん".utf8)))
    }

    func testSortsFailuresByStatusCode() {
        XCTAssertEqual(execute(statusCode: 401), .failure(.unauthorized))
        XCTAssertEqual(execute(statusCode: 403), .failure(.forbidden))
        XCTAssertEqual(execute(statusCode: 429), .failure(.rateLimited))
        XCTAssertEqual(execute(statusCode: 500), .failure(.serverError))
        XCTAssertEqual(execute(statusCode: 503), .failure(.serverError))
        XCTAssertEqual(execute(statusCode: 418), .failure(.unexpectedStatus(418)))
    }

    func testReportsNoResponseWhenRequestNeverArrives() {
        XCTAssertEqual(execute(statusCode: nil), .failure(.noResponse))
    }

    //応答がそのまま画面へバインドされるため、購読側で何も指定しなくても
    //メインスレッドで受け取れることが前提になっている
    func testDeliversResultOnMainThread() {
        StubUrlProtocol.stubbedStatusCode = 200
        let expectation = self.expectation(description: "応答を受け取る")
        var receivedOnMainThread = false

        apiClient.execute(urlRequest: URLRequest(url: requestUrl))
            .subscribe(onNext: { _ in
                receivedOnMainThread = Thread.isMainThread
                expectation.fulfill()
            })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: responseWaitLimit)

        XCTAssertTrue(receivedOnMainThread)
    }

    //v1.1のタイムライン取得が使う経路。エラー時の本文を渡さないことで、
    //応答をそのままデコードしにいく既存の流れが壊れないことを確かめる
    func testHttpRequestHidesBodyOfFailedResponse() {
        StubUrlProtocol.stubbedStatusCode = 401
        StubUrlProtocol.stubbedBody = Data("エラー本文".utf8)
        let expectation = self.expectation(description: "応答を受け取る")
        var received: Data? = Data("まだ受け取っていない".utf8)

        apiClient.executeHttpRequest(urlRequest: URLRequest(url: requestUrl))
            .subscribe(onNext: {
                received = $0
                expectation.fulfill()
            })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: responseWaitLimit)

        XCTAssertNil(received)
    }

    private func execute(statusCode: Int?) -> Result<Data, ApiError>? {
        StubUrlProtocol.stubbedStatusCode = statusCode
        let expectation = self.expectation(description: "応答を受け取る")
        var received: Result<Data, ApiError>? = nil

        apiClient.execute(urlRequest: URLRequest(url: requestUrl))
            .subscribe(onNext: {
                received = $0
                expectation.fulfill()
            })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: responseWaitLimit)

        return received
    }
}

//URLProtocolで差し替えているのは、ステータスコードの読み分けを
//Xへ実際に問い合わせず、課金も伴わずに確かめるため
private class StubUrlProtocol: URLProtocol {
    static var stubbedStatusCode: Int? = nil
    static var stubbedBody = Data()

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let statusCode = StubUrlProtocol.stubbedStatusCode,
            let url = request.url,
            let response = HTTPURLResponse(url: url,
                                           statusCode: statusCode,
                                           httpVersion: "HTTP/1.1",
                                           headerFields: nil) else {
                                            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
                                            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: StubUrlProtocol.stubbedBody)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() { }
}
