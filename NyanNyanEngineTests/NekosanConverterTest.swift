//
//  NekosanConverterTest.swift
//  NyanNyanEngineTests
//
//  Created by Tetsuya Nishikawa on 2019/05/06.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import XCTest
@testable import NyanNyanEngine

class NekosanConverterTest: XCTestCase {
    func testNekosan() {
        let testStr = "どんな嫌なツイートでも、猫語だと可愛いですね。"
        
        let testNekogo = Nekosan().createNekogo(sourceStr: testStr)
        let expectedNekogo = "MyauMiaowMew🌈"
        XCTAssertEqual(testNekogo, expectedNekogo)
    }
    
    func testDoesNekosanRemainNekogo() {
        let rawStr = ["MyauMewMiaow",
                      "MeoowMeoowMyau🐟",
                      "MeeowMeeowMeeow"]
        let testStrs = rawStr.map { Nekosan().createNekogo(sourceStr: $0) }
        let expectedStrs = rawStr
        
        XCTAssertEqual(testStrs, expectedStrs)
    }
}
