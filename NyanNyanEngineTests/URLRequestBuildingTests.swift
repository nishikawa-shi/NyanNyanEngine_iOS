//
//  URLRequestBuildingTests.swift
//  NyanNyanEngineTests
//
//  Created by Tetsuya Nishikawa on 2026/08/30.
//  Copyright © 2026 Tetsuya Nishikawa. All rights reserved.
//

import XCTest
@testable import NyanNyanEngine

class URLRequestBuildingTests: XCTestCase {

    private let baseRequest = URLRequest(url: URL(string: "https://api.x.com/2/tweets")!)

    func testAddingHeaderReturnsRequestCarryingIt() {
        let request = baseRequest.adding(header: "application/json", forField: "Content-Type")

        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    func testPostingSetsMethodAndBody() {
        let body = Data("にゃーん".utf8)

        let request = baseRequest.posting(body: body)

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.httpBody, body)
    }

    //元のリクエストが書き換わらないことが、呼び出し側で可変な束縛を
    //持たずに済む前提になっている
    func testOriginalRequestStaysUntouched() {
        _ = baseRequest
            .posting(body: Data("にゃーん".utf8))
            .adding(header: "application/json", forField: "Content-Type")

        XCTAssertNil(baseRequest.httpBody)
        XCTAssertNil(baseRequest.value(forHTTPHeaderField: "Content-Type"))
        XCTAssertEqual(baseRequest.httpMethod, "GET")
    }

    func testCanChainSeveralHeaders() {
        let request = baseRequest
            .adding(header: "application/json", forField: "Content-Type")
            .adding(header: "Bearer にゃーん", forField: "Authorization")

        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer にゃーん")
    }
}
