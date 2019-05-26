//
//  DateFormatterTest.swift
//  NyanNyanEngineTests
//
//  Created by Tetsuya Nishikawa on 2019/05/06.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import XCTest
@testable import NyanNyanEngine

class DateFormatterTest: XCTestCase {
    func testGetNyanNyanTimeStamp() {
        let testApiTimeStamp = "Fri Apr 03 10:12:54 +0000 2018"
        let testNyanNyanTimeStamp = TwitterDateFormatter().getNyanNyanTimeStamp(apiTimeStamp: testApiTimeStamp)
        let expectedNyanNyanTimeStamp = "2018/04"
        XCTAssertEqual(testNyanNyanTimeStamp, expectedNyanNyanTimeStamp)
    }
}
