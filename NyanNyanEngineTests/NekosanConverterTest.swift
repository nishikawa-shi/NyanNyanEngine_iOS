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
        let expectedNekogo = "にゃーおんにゃおにゃー🌈"
        XCTAssertEqual(testNekogo, expectedNekogo)
    }
}
