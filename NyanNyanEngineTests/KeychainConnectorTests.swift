//
//  KeychainConnectorTests.swift
//  NyanNyanEngineTests
//
//  Created by Tetsuya Nishikawa on 2026/08/30.
//  Copyright © 2026 Tetsuya Nishikawa. All rights reserved.
//

import XCTest
@testable import NyanNyanEngine

class KeychainConnectorTests: XCTestCase {

    private var connector: KeychainConnector!
    private let authStateKey = "x_auth_state"
    private let otherKey = "x_other_record"

    override func setUp() {
        super.setUp()
        connector = KeychainConnector(service: "com.ntetz.ios.NyanNyanEngine.keychainTests")
        connector.deleteRecord(forKey: authStateKey)
        connector.deleteRecord(forKey: otherKey)
    }

    override func tearDown() {
        connector.deleteRecord(forKey: authStateKey)
        connector.deleteRecord(forKey: otherKey)
        super.tearDown()
    }

    func testReturnsNilWhenNothingSaved() {
        XCTAssertNil(connector.getData(withKey: authStateKey))
    }

    func testSavedValueCanBeReadBack() {
        let saved = Data("にゃーん".utf8)

        let succeeded = connector.registerData(key: authStateKey, value: saved)

        XCTAssertTrue(succeeded)
        XCTAssertEqual(connector.getData(withKey: authStateKey), saved)
    }

    func testSavingTwiceOverwritesInsteadOfDuplicating() {
        _ = connector.registerData(key: authStateKey, value: Data("ふるい".utf8))
        let succeeded = connector.registerData(key: authStateKey, value: Data("あたらしい".utf8))

        XCTAssertTrue(succeeded)
        XCTAssertEqual(connector.getData(withKey: authStateKey), Data("あたらしい".utf8))
    }

    //Keychainは空データも受け付けるため、保存されたものと
    //「保存されていない」状態が区別できることを確かめる
    func testEmptyValueIsDistinguishableFromAbsence() {
        let succeeded = connector.registerData(key: authStateKey, value: Data())

        XCTAssertTrue(succeeded)
        XCTAssertEqual(connector.getData(withKey: authStateKey), Data())
        XCTAssertNil(connector.getData(withKey: otherKey))
    }

    //OIDAuthStateのアーカイブは数百バイトのバイナリになるため、
    //UTF-8として解釈できないバイト列でも往復できることを確かめる
    func testBinaryValueSurvivesRoundTrip() {
        let binary = Data((0...255).map { UInt8($0) })

        _ = connector.registerData(key: authStateKey, value: binary)

        XCTAssertEqual(connector.getData(withKey: authStateKey), binary)
    }

    func testDeletedValueIsGone() {
        _ = connector.registerData(key: authStateKey, value: Data("にゃーん".utf8))
        connector.deleteRecord(forKey: authStateKey)

        XCTAssertNil(connector.getData(withKey: authStateKey))
    }

    func testDeletingAbsentKeyDoesNotCrash() {
        connector.deleteRecord(forKey: "存在しないキー")
    }

    func testKeysAreIsolatedFromEachOther() {
        _ = connector.registerData(key: authStateKey, value: Data("認証状態".utf8))
        _ = connector.registerData(key: otherKey, value: Data("べつのもの".utf8))

        connector.deleteRecord(forKey: otherKey)

        XCTAssertEqual(connector.getData(withKey: authStateKey), Data("認証状態".utf8))
        XCTAssertNil(connector.getData(withKey: otherKey))
    }
}
