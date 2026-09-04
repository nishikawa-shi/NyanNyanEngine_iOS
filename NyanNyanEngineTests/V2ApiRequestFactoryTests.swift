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

    private let factory = V2ApiRequestFactory.shared

    func testMyAccountRequestAsksForProfileImage() {
        let request = factory.createMyAccountRequest()

        XCTAssertEqual(request?.url?.absoluteString,
                       "https://api.x.com/2/users/me?user.fields=profile_image_url")
        XCTAssertEqual(request?.httpMethod, "GET")
    }

    //Authorizationの付与はXAuthClientの責務のため、ここでは載らないことを確かめる
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

    //トークンに「+」や「=」が含まれても壊れずに届くことを確かめる。
    //クエリ文脈のエンコードでは、この2文字が素通しになる
    func testRevokeTokenRequestEncodesBodyForForm() {
        let request = factory.createRevokeTokenRequest(token: "ab+cd=ef",
                                                       tokenTypeHint: "refresh_token",
                                                       clientId: "nyannyan-client-id")

        XCTAssertEqual(request?.url?.absoluteString, "https://api.x.com/2/oauth2/revoke")
        XCTAssertEqual(request?.httpMethod, "POST")
        XCTAssertEqual(request?.value(forHTTPHeaderField: "Content-Type"), "application/x-www-form-urlencoded")
        XCTAssertEqual(request?.httpBody.flatMap { String(data: $0, encoding: .utf8) },
                       "token=ab%2Bcd%3Def&token_type_hint=refresh_token&client_id=nyannyan-client-id")
    }

    //v1.1のcreatePostTweetRequestは本文をURLへ載せていたため、
    //猫語の絵文字や記号がエンコードの差で壊れうる形だった
    func testPostTweetRequestKeepsBodyOutOfUrl() {
        let request = factory.createPostTweetRequest(tweetBody: "にゃーん🐾")

        XCTAssertNil(request?.url?.query)
    }
}
