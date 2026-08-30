//
//  V2JsonDecodeTests.swift
//  NyanNyanEngineTests
//
//  Created by Tetsuya Nishikawa on 2026/08/30.
//  Copyright © 2026 Tetsuya Nishikawa. All rights reserved.
//

import XCTest
@testable import NyanNyanEngine

//JSONは 2026-08-30 に実際のX APIから受け取った応答をそのまま使っている
class V2JsonDecodeTests: XCTestCase {

    private var decoder: JSONDecoder?

    override func setUp() {
        decoder = JSONDecoder()
        decoder?.keyDecodingStrategy = .convertFromSnakeCase
    }

    func testCanParseMyAccount() {
        let testJson = """
            {
                "data": {
                    "id": "1568466609035161600",
                    "name": "nishik",
                    "profile_image_url": "https://pbs.twimg.com/profile_images/1568466676425039874/vCcKwevh_normal.png",
                    "username": "nishik75"
                }
            }
            """.data(using: .utf8)!

        let response = try! decoder!.decode(V2UserResponse.self, from: testJson)

        XCTAssertEqual(response.data.id, "1568466609035161600")
        XCTAssertEqual(response.data.name, "nishik")
        XCTAssertEqual(response.data.username, "nishik75")
    }

    func testMyAccountCarriesIdUsedForNyanNyanPoint() {
        let testJson = """
            {
                "data": {
                    "id": "1568466609035161600",
                    "name": "nishik",
                    "profile_image_url": "https://pbs.twimg.com/profile_images/1568466676425039874/vCcKwevh_normal.png",
                    "username": "nishik75"
                }
            }
            """.data(using: .utf8)!

        let user = try! decoder!.decode(V2UserResponse.self, from: testJson).data

        XCTAssertEqual(user.id, "1568466609035161600")
        XCTAssertEqual(user.username, "nishik75")
    }

    //取得したURLは_normalサフィックス付きのため、高解像度版へ読み替えられることを確かめる
    func testProfileImageUrlDropsNormalSuffix() {
        let testJson = """
            {
                "data": {
                    "id": "1568466609035161600",
                    "name": "nishik",
                    "profile_image_url": "https://pbs.twimg.com/profile_images/1568466676425039874/vCcKwevh_normal.png",
                    "username": "nishik75"
                }
            }
            """.data(using: .utf8)!

        let user = try! decoder!.decode(V2UserResponse.self, from: testJson).data

        XCTAssertEqual(user.getFineImageUrl(),
                       "https://pbs.twimg.com/profile_images/1568466676425039874/vCcKwevh.png")
    }

    func testCanParseMyAccountWithoutProfileImage() {
        let testJson = """
            {
                "data": {
                    "id": "1568466609035161600",
                    "name": "nishik",
                    "username": "nishik75"
                }
            }
            """.data(using: .utf8)!

        let response = try! decoder!.decode(V2UserResponse.self, from: testJson)

        XCTAssertEqual(response.data.username, "nishik75")
        XCTAssertNil(response.data.profileImageUrl)
    }

    func testCanParsePostedTweet() {
        let testJson = """
            {
                "data": {
                    "edit_history_tweet_ids": [
                        ""
                    ],
                    "id": "2093888122887221687",
                    "text": "にゃーん🐾"
                }
            }
            """.data(using: .utf8)!

        let response = try! decoder!.decode(V2TweetResponse.self, from: testJson)

        XCTAssertEqual(response.data.id, "2093888122887221687")
        XCTAssertEqual(response.data.text, "にゃーん🐾")
    }
}
