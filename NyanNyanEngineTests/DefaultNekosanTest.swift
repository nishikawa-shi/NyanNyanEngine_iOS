//
//  DefaultNekosanTest.swift
//  NyanNyanEngineTests
//
//  Created by Tetsuya Nishikawa on 2026/08/16.
//  Copyright © 2026 Tetsuya Nishikawa. All rights reserved.
//

import XCTest
@testable import NyanNyanEngine

class DefaultNekosanTest: XCTestCase {
    //タイムライン取得に失敗した時の表示が、ネットワーク越しの画像に依存していないこと
    func testDefaultNekosanHasNoRemoteProfileUrl() {
        XCTAssertNil(DefaultNekosan().nyanNyanStatuses[0].profileUrl)
    }

    //ログイン前のアカウント表示が、ネットワーク越しの画像に依存していないこと
    func testDefaultAccountHasNoRemoteProfileUrl() {
        XCTAssertNil(Account().user.profileImageUrlHttps)
    }

    //デフォルトアカウントの定義がAccountとAuthRepositoryに二重管理されると壊れる箇所の回帰テスト
    func testDefaultAccountIsJudgedAsDefault() {
        XCTAssertTrue(Account().isDefaultAccount())
    }

    //URLを持たないネコさんに出すにゃんにゃ先生のアイコンが、バンドルに実在すること
    func testSenseiIconExistsInBundle() {
        XCTAssertNotNil(R.image.nyanNyaSenseiIcon())
    }

    //アイコンを取得できなかった時に出す名無しのネコさんが、バンドルに実在すること
    func testUnknownUserImageExistsInBundle() {
        XCTAssertNotNil(R.image.defaultUser())
    }
}
