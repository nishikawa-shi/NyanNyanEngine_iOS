//
//  NekosanTest.swift
//  NyanNyanEngineTests
//
//  Created by Tetsuya Nishikawa on 2/23/20.
//  Copyright © 2020 Tetsuya Nishikawa. All rights reserved.
//

import XCTest
import CryptoSwift
@testable import NyanNyanEngine

class NekosanTest: XCTestCase {
    func testIsNekogo() {
        XCTAssertTrue(Nekosan().isNekogo(sourceStr: "MiaaaowMiaaaowMiaaaow😊 #MeowMeowEngine #PetMeMeeow🧶"))
    }
    
    func testAngou() {
        let sigKey = "abc"
        let sigData = "abc"
        let angou = calcAngou(sigKey: sigKey, sigData: sigData)
        XCTAssertEqual(angou, "WzM6OJtOmiNYrFOSvypk3GjjyUM=")
    }
    
    func testAngou2() {
        let sigKey = "abc"
        let sigData = "def"
        let angou = calcAngou(sigKey: sigKey, sigData: sigData)
        XCTAssertEqual(angou, "ElVOq7r36OEuRzcCD5h8p5AQFuU=")
    }
    
    func testAngou3() {
        let sigKey = "BjE059cB3ZeYey9ewvhzLjTbLRV1OgMCoB2Re4UD6lymdIafQ8&"
        let sigData = "ghi"
        let angou = calcAngou(sigKey: sigKey, sigData: sigData)
        XCTAssertEqual(angou, "uAP7OTWLzMXaEuTrazWwLUhDzqc=")
    }
    
    func testAngou4() {
        let sigKey = "BjE059cB3ZeYey9ewvhzLjTbLRV1OgMCoB2Re4UD6lymdIafQ8&"
        let sigData = "https%3A%2F%2Fapi.twitter.com%2Foauth%2Frequest_token&"
        let angou = calcAngou(sigKey: sigKey, sigData: sigData)
        XCTAssertEqual(angou, "3dNfdDl6UVJk2b2LJ6Krl/N9o+Y=")
    }

    func testAngou5() {
        let sigKey = "BjE059cB3ZeYey9ewvhzLjTbLRV1OgMCoB2Re4UD6lymdIafQ8&"
        let sigData = "POST&https%3A%2F%2Fapi.twitter.com%2Foauth%2Frequest_token&oauth_callback%3Dhttps%253A%252F%252Fnyannyanengine-ios-d.firebaseapp.com%252Fauthorized%252F%26"
        let angou = calcAngou(sigKey: sigKey, sigData: sigData)
        XCTAssertEqual(angou, "AWeerJ3Blvr0FNp2SnaXiqmgdZc=")
    }
    
    func testAngou6() {
        let sigKey = "BjE059cB3ZeYey9ewvhzLjTbLRV1OgMCoB2Re4UD6lymdIafQ8&"
        let sigData = "POST&https%3A%2F%2Fapi.twitter.com%2Foauth%2Frequest_token&oauth_callback%3Dhttps%253A%252F%252Fnyannyanengine-ios-d.firebaseapp.com%252Fauthorized%252F%26oauth_consumer_key%3DwL3S6dYhyW94ZRLVXg9JqaqUT%26oauth_nonce%3D0000%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1595059320%26oauth_token%3D%26oauth_version%3D1.0"
        let angou = calcAngou(sigKey: sigKey, sigData: sigData)
        XCTAssertEqual(angou, "dHGB6RBLiLCfNgbG7WR4h6RIu18=")
    }
    
    private func calcAngou(sigKey: String, sigData: String) -> String {
        let sigKeyByte = sigKey.data(using: .utf8)!.bytes
        print("nekosa-n sigKeyByte is \(sigKeyByte)")

        let sigDataByte = sigData.data(using: .utf8)!.bytes
        print("nekosa-n sigDataByte is \(sigDataByte)")

        let hmac = try! HMAC(key: sigKeyByte, variant: .sha1).authenticate(sigDataByte)
        print("nekosa-n hmac is \(hmac)")

        let encodedHmac = Data(hmac).base64EncodedString()
        print("nekosa-n encodedHmac is \(encodedHmac)")
        
        return encodedHmac
    }
}
