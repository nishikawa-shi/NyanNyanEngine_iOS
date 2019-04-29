//
//  ObjectMappingTests.swift
//  NyanNyanEngineTests
//
//  Created by Tetsuya Nishikawa on 2019/04/29.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import XCTest
@testable import NyanNyanEngine

class JsonDecodeTests: XCTestCase {
    
    private var decoder: JSONDecoder?
    
    override func setUp() {
        decoder = JSONDecoder()
        decoder?.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    func testCanParseHomeTimeLine() {
        let testJson = """
            [
                {
                    "coordinates": null,
                    "truncated": false,
                    "created_at": "Sun Apr 28 21:00:00 +0000 2019",
                    "favorited": false,
                    "id_str": "240558470661799936",
                    "in_reply_to_user_id_str": null,
                    "entities": {
                        "urls": [],
                        "hashtags": [],
                        "user_mentions": []
                    },
                    "text": "28日は、ちょーいい日で、めっちゃ笑って、水飲んで寝た",
                    "contributors": null,
                    "id": 240558470661799936,
                    "retweet_count": 0,
                    "in_reply_to_status_id_str": null,
                    "geo": null,
                    "retweeted": false,
                    "in_reply_to_user_id": null,
                    "place": null,
                    "source": "OAuth Dancer Reborn",
                    "user": {
                        "name": "ハイボールマン 3号",
                        "profile_sidebar_fill_color": "DDEEF6",
                        "profile_background_tile": true,
                        "profile_sidebar_border_color": "C0DEED",
                        "profile_image_url": "http://a0.twimg.com/profile_images/730275945/oauth-dancer_normal.jpg",
                        "created_at": "Wed Mar 03 19:37:35 +0000 2010",
                        "location": "San Francisco, CA",
                        "follow_request_sent": false,
                        "id_str": "119476949",
                        "is_translator": false,
                        "profile_link_color": "0084B4",
                        "entities": {
                            "url": {
                                "urls": [
                                    {
                                        "expanded_url": null,
                                        "url": "http://bit.ly/oauth-dancer",
                                        "indices": [
                                            0,
                                            26
                                        ],
                                        "display_url": null
                                    }
                                ]
                            },
                            "description": null
                        },
                        "default_profile": false,
                        "url": "http://bit.ly/oauth-dancer",
                        "contributors_enabled": false,
                        "favourites_count": 7,
                        "utc_offset": null,
                        "profile_image_url_https": "https://si0.twimg.com/profile_images/730275945/oauth-dancer_normal.jpg",
                        "id": 119476949,
                        "listed_count": 1,
                        "profile_use_background_image": true,
                        "profile_text_color": "333333",
                        "followers_count": 28,
                        "lang": "en",
                        "protected": false,
                        "geo_enabled": true,
                        "notifications": false,
                        "description": "",
                        "profile_background_color": "C0DEED",
                        "verified": false,
                        "time_zone": null,
                        "profile_background_image_url_https": "https://si0.twimg.com/profile_background_images/80151733/oauth-dance.png",
                        "statuses_count": 166,
                        "profile_background_image_url": "http://a0.twimg.com/profile_background_images/80151733/oauth-dance.png",
                        "default_profile_image": false,
                        "friends_count": 14,
                        "following": false,
                        "show_all_inline_media": false,
                        "screen_name": "oauth_dancer"
                    },
                    "in_reply_to_screen_name": null,
                    "in_reply_to_status_id": null
                },
            ]
        """.data(using: .utf8)!
        
        let testStatusObj = try! decoder!.decode([Status].self, from: testJson).first!
        
        XCTAssertEqual(testStatusObj.createdAt, "Sun Apr 28 21:00:00 +0000 2019")
        XCTAssertEqual(testStatusObj.text, "28日は、ちょーいい日で、めっちゃ笑って、水飲んで寝た")
        XCTAssertEqual(testStatusObj.user.name, "ハイボールマン 3号")
        XCTAssertEqual(testStatusObj.favorited, false)
        XCTAssertEqual(testStatusObj.retweeted, false)
    }
    
    func testCanParseStatus() {
        let testJson = """
            {
                "coordinates": null,
                "truncated": false,
                "created_at": "Sun Apr 28 21:00:00 +0000 2019",
                "favorited": false,
                "id_str": "240558470661799936",
                "in_reply_to_user_id_str": null,
                "entities": {
                    "urls": [],
                    "hashtags": [],
                    "user_mentions": []
                },
                "text": "28日は、ちょーいい日で、めっちゃ笑って、水飲んで寝た",
                "contributors": null,
                "id": 240558470661799936,
                "retweet_count": 0,
                "in_reply_to_status_id_str": null,
                "geo": null,
                "retweeted": false,
                "in_reply_to_user_id": null,
                "place": null,
                "source": "OAuth Dancer Reborn",
                "user": {
                    "name": "ハイボールマン 3号",
                    "profile_sidebar_fill_color": "DDEEF6",
                    "profile_background_tile": true,
                    "profile_sidebar_border_color": "C0DEED",
                    "profile_image_url": "http://a0.twimg.com/profile_images/730275945/oauth-dancer_normal.jpg",
                    "created_at": "Wed Mar 03 19:37:35 +0000 2010",
                    "location": "San Francisco, CA",
                    "follow_request_sent": false,
                    "id_str": "119476949",
                    "is_translator": false,
                    "profile_link_color": "0084B4",
                    "entities": {
                        "url": {
                            "urls": [
                                {
                                    "expanded_url": null,
                                    "url": "http://bit.ly/oauth-dancer",
                                    "indices": [
                                        0,
                                        26
                                    ],
                                    "display_url": null
                                }
                            ]
                        },
                        "description": null
                    },
                    "default_profile": false,
                    "url": "http://bit.ly/oauth-dancer",
                    "contributors_enabled": false,
                    "favourites_count": 7,
                    "utc_offset": null,
                    "profile_image_url_https": "https://si0.twimg.com/profile_images/730275945/oauth-dancer_normal.jpg",
                    "id": 119476949,
                    "listed_count": 1,
                    "profile_use_background_image": true,
                    "profile_text_color": "333333",
                    "followers_count": 28,
                    "lang": "en",
                    "protected": false,
                    "geo_enabled": true,
                    "notifications": false,
                    "description": "",
                    "profile_background_color": "C0DEED",
                    "verified": false,
                    "time_zone": null,
                    "profile_background_image_url_https": "https://si0.twimg.com/profile_background_images/80151733/oauth-dance.png",
                    "statuses_count": 166,
                    "profile_background_image_url": "http://a0.twimg.com/profile_background_images/80151733/oauth-dance.png",
                    "default_profile_image": false,
                    "friends_count": 14,
                    "following": false,
                    "show_all_inline_media": false,
                    "screen_name": "oauth_dancer"
                },
                "in_reply_to_screen_name": null,
                "in_reply_to_status_id": null
            }
        """.data(using: .utf8)!
        
        let testStatusObj = try! decoder!.decode(Status.self, from: testJson)
        
        XCTAssertEqual(testStatusObj.createdAt, "Sun Apr 28 21:00:00 +0000 2019")
        XCTAssertEqual(testStatusObj.text, "28日は、ちょーいい日で、めっちゃ笑って、水飲んで寝た")
        XCTAssertEqual(testStatusObj.user.name, "ハイボールマン 3号")
        XCTAssertEqual(testStatusObj.favorited, false)
        XCTAssertEqual(testStatusObj.retweeted, false)
    }
    
    func testCanParseUser() {
        let testJson = """
            {
                "name": "ハイボールマン 3号",
                "profile_sidebar_fill_color": "DDEEF6",
                "profile_background_tile": true,
                "profile_sidebar_border_color": "C0DEED",
                "profile_image_url": "http://a0.twimg.com/profile_images/730275945/oauth-dancer_normal.jpg",
                "created_at": "Wed Mar 03 19:37:35 +0000 2010",
                "location": "San Francisco, CA",
                "follow_request_sent": false,
                "id_str": "119476949",
                "is_translator": false,
                "profile_link_color": "0084B4",
                "entities": {
                    "url": {
                        "urls": [
                            {
                                "expanded_url": null,
                                "url": "http://bit.ly/oauth-dancer",
                                "indices": [
                                    0,
                                    26
                                ],
                                "display_url": null
                            }
                        ]
                    },
                    "description": null
                },
                "default_profile": false,
                "url": "http://bit.ly/oauth-dancer",
                "contributors_enabled": false,
                "favourites_count": 7,
                "utc_offset": null,
                "profile_image_url_https": "https://si0.twimg.com/profile_images/730275945/oauth-dancer_normal.jpg",
                "id": 119476949,
                "listed_count": 1,
                "profile_use_background_image": true,
                "profile_text_color": "333333",
                "followers_count": 28,
                "lang": "en",
                "protected": false,
                "geo_enabled": true,
                "notifications": false,
                "description": "",
                "profile_background_color": "C0DEED",
                "verified": false,
                "time_zone": null,
                "profile_background_image_url_https": "https://si0.twimg.com/profile_background_images/80151733/oauth-dance.png",
                "statuses_count": 166,
                "profile_background_image_url": "http://a0.twimg.com/profile_background_images/80151733/oauth-dance.png",
                "default_profile_image": false,
                "friends_count": 14,
                "following": false,
                "show_all_inline_media": false,
                "screen_name": "oauth_dancer"
            }
        """.data(using: .utf8)!
        
        let testUserObj = try! decoder!.decode(User.self, from: testJson)
        
        XCTAssertEqual(testUserObj.name, "ハイボールマン 3号")
        XCTAssertEqual(testUserObj.profileImageUrlHttps, "https://si0.twimg.com/profile_images/730275945/oauth-dancer_normal.jpg")
        XCTAssertEqual(testUserObj.statusesCount, 166)
    }
    
    func testCanParseEntity() {
        let testJson = """
            {
                "urls": [],
                "hashtags": [],
                "user_mentions": []
            }
        """.data(using: .utf8)!
        let testEntityObj = try! decoder!.decode(Entity.self, from: testJson)
        
        XCTAssertTrue(testEntityObj.urls.isEmpty)
        XCTAssertTrue(testEntityObj.userMentions.isEmpty)
    }
    
    func testCanParseUrl() {
        let testJson = """
            {
                "expanded_url": "http://blogs.ischool.berkeley.edu/i290-abdt-s12/",
                "url": "http://t.co/bfj7zkDJ",
                "indices": [
                    79,
                    99
                ],
                "display_url": "blogs.ischool.berkeley.edu/i290-abdt-s12/"
            }
        """.data(using: .utf8)!
        let testUrlObj = try! decoder!.decode(Url.self, from: testJson)
        
        XCTAssertEqual(testUrlObj.expandedUrl, "http://blogs.ischool.berkeley.edu/i290-abdt-s12/")
        XCTAssertEqual(testUrlObj.indices, [79, 99])
    }
    
    func testCanParseUserMention() {
        let testJson = """
            {
                "name": "Tetsuya Nishikawa",
                "id_str": "20495814",
                "id": 20495814,
                "indices": [
                    70,
                    77
                ],
                "screen_name": "にしかわ"
            }
        """.data(using: .utf8)!
        let testUserMentionObj = try! decoder!.decode(UserMention.self, from: testJson)
        
        XCTAssertEqual(testUserMentionObj.name, "Tetsuya Nishikawa")
        XCTAssertEqual(testUserMentionObj.id, 20495814)
        XCTAssertEqual(testUserMentionObj.screenName, "にしかわ")
    }
    
}
