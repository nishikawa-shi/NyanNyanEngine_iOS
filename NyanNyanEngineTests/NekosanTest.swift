//
//  NekosanTest.swift
//  NyanNyanEngineTests
//
//  Created by Tetsuya Nishikawa on 2/23/20.
//  Copyright © 2020 Tetsuya Nishikawa. All rights reserved.
//

import XCTest
@testable import NyanNyanEngine

class NekosanTest: XCTestCase {
    func testIsNekogo() {
        XCTAssertTrue(Nekosan().isNekogo(sourceStr: "MiaaaowMiaaaowMiaaaow😊 #MeowMeowEngine #PetMeMeeow🧶"))
    }
}
