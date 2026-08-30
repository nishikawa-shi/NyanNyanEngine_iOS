//
//  V2ApiRequestFactoryTests.swift
//  NyanNyanEngineTests
//
//  Created by Tetsuya Nishikawa on 2026/08/30.
//  Copyright © 2026 Tetsuya Nishikawa. All rights reserved.
//

import XCTest
@testable import NyanNyanEngine

class V2ApiRequestFactoryTests: XCTestCase {

    private let factory = V2ApiRequestFactory()

    func testMyAccountRequestAsksForProfileImage() {
        let request = factory.createMyAccountRequest()

        XCTAssertEqual(request?.url?.absoluteString,
                       "https://api.x.com/2/users/me?user.fields=profile_image_url")
        XCTAssertEqual(request?.httpMethod, "GET")
    }

    //Authorizationの付与はXAuthServiceの責務のため、ここでは載らないことを確かめる
    func testRequestsCarryNoAuthorizationHeader() {
        XCTAssertNil(factory.createMyAccountRequest()?
            .value(forHTTPHeaderField: "Authorization"))
        XCTAssertNil(factory.createPostTweetRequest(tweetBody: "にゃーん")?
            .value(forHTTPHeaderField: "Authorization"))
    }

    func testPostTweetRequestSendsTextAsJson() {
        let request = factory.createPostTweetRequest(tweetBody: "にゃーん🐾")

        XCTAssertEqual(request?.url?.absoluteString, "https://api.x.com/2/tweets")
        XCTAssertEqual(request?.httpMethod, "POST")
        XCTAssertEqual(request?.value(forHTTPHeaderField: "Content-Type"), "application/json")

        let body = request?.httpBody.flatMap { try? JSONDecoder().decode([String: String].self, from: $0) }
        XCTAssertEqual(body?["text"], "にゃーん🐾")
    }

    //v1.1のcreatePostTweetRequestは本文をURLへ載せていたため、
    //猫語の絵文字や記号がエンコードの差で壊れうる形だった
    func testPostTweetRequestKeepsBodyOutOfUrl() {
        let request = factory.createPostTweetRequest(tweetBody: "にゃーん🐾")

        XCTAssertNil(request?.url?.query)
    }
}
