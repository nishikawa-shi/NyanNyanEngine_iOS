//
//  V2JsonDecodeTests.swift
//  NyanNyanEngineTests
//
//  Created by Tetsuya Nishikawa on 2026/08/30.
//  Copyright © 2026 Tetsuya Nishikawa. All rights reserved.
//

import XCTest
@testable import NyanNyanEngine

//JSONは、特記のない限り 2026-08-30 に実際のX APIから受け取った応答をそのまま使っている
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

    //ここから下のJSONだけは実際の応答ではなく、2026-09-21時点の公式スキーマから
    //組み立てたもの。タイムライン取得は1回叩くごとにXへの支払いが発生するため、
    //形の確認のためだけには呼んでいない。実物との突き合わせは実機で行う
    func testCanParseHomeTimeline() {
        let testJson = """
            {
                "data": [
                    {
                        "created_at": "2019-12-15T12:00:00.000Z",
                        "id": "2093888122887221687",
                        "edit_history_tweet_ids": ["2093888122887221687"],
                        "text": "28日は、ちょーいい日で、めっちゃ笑って、水飲んで寝た",
                        "author_id": "1568466609035161600"
                    }
                ],
                "includes": {
                    "users": [
                        {
                            "id": "1568466609035161600",
                            "name": "nishik",
                            "username": "nishik75",
                            "profile_image_url": "https://pbs.twimg.com/profile_images/1568466676425039874/vCcKwevh_normal.png"
                        }
                    ]
                },
                "meta": {
                    "result_count": 1,
                    "newest_id": "2093888122887221687",
                    "oldest_id": "2093888122887221687"
                }
            }
            """.data(using: .utf8)!

        let response = try! decoder!.decode(V2TimelineResponse.self, from: testJson)

        XCTAssertEqual(response.data?.first?.id, "2093888122887221687")
        XCTAssertEqual(response.data?.first?.text, "28日は、ちょーいい日で、めっちゃ笑って、水飲んで寝た")
        XCTAssertEqual(response.data?.first?.createdAt, "2019-12-15T12:00:00.000Z")
        XCTAssertEqual(response.data?.first?.authorId, "1568466609035161600")
        XCTAssertEqual(response.includes?.users?.first?.name, "nishik")
        XCTAssertEqual(response.includes?.users?.first?.username, "nishik75")
    }

    //フォロー先に新しい投稿が1つも無いとき、Xはdataそのものを書かずに返す。
    //必須にすると、静かなタイムラインが「読めなかった」と同じ扱いになる
    func testCanParseTimelineWithoutPosts() {
        let testJson = """
            {
                "meta": {
                    "result_count": 0
                }
            }
            """.data(using: .utf8)!

        let response = try! decoder!.decode(V2TimelineResponse.self, from: testJson)

        XCTAssertNil(response.data)
        XCTAssertNil(response.includes)
    }

    //要求した属性が欠けても、読めたツイートまで巻き添えで消えないこと。
    //1つ足りないだけでデコードは丸ごと失敗する
    func testCanParseTimelineWhenPostLacksCreatedAt() {
        let testJson = """
            {
                "data": [
                    {
                        "id": "2093888122887221687",
                        "text": "にゃーん🐾",
                        "author_id": "1568466609035161600"
                    }
                ]
            }
            """.data(using: .utf8)!

        let response = try! decoder!.decode(V2TimelineResponse.self, from: testJson)

        XCTAssertEqual(response.data?.first?.text, "にゃーん🐾")
        XCTAssertNil(response.data?.first?.createdAt)
    }
}
