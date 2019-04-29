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

}
