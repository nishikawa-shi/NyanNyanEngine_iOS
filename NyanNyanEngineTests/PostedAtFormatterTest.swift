//
//  PostedAtFormatterTest.swift
//  NyanNyanEngineTests
//
//  Created by Tetsuya Nishikawa on 2019/05/06.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import XCTest
@testable import NyanNyanEngine

//書式を読めなかったことは例外にもビルドエラーにもならず、既定の文字列へ
//静かに倒れる。一覧に並ぶ時刻が全件同じになるまで誰も気づかないため、
//読める形と読めない形の両方をここで固定している。
//言い回しそのものを期待値にしていないのは、それを決めるのがOSの各言語データで、
//時が経つだけでも変わるため。ここで確かめたいのは書式を読めたか
class PostedAtFormatterTest: XCTestCase {
    //経過時間で見ているのは、読めたことだけでなく、読んだ時刻が正しいことを
    //確かめるため。時間帯の解釈を誤ると、読めてはいるが何時間もずれ、
    //10という数字が出てこなくなる
    func testReadsTimeStampXSends() {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let tenMinutesAgo = isoFormatter.string(from: Date().addingTimeInterval(-60 * 10))

        let nyanNyanTimeStamp = PostedAtFormatter().getNyanNyanTimeStamp(apiTimeStamp: tenMinutesAgo)

        XCTAssertTrue(nyanNyanTimeStamp.contains("10"), "10分前として読めていない: \(nyanNyanTimeStamp)")
    }

    //2026-09-21時点の公式ドキュメントが created_at の例として載せている値。
    //Xが返す形が変わったらここが落ちる
    func testReadsTimeStampDocumentedByX() {
        let nyanNyanTimeStamp = PostedAtFormatter()
            .getNyanNyanTimeStamp(apiTimeStamp: "2019-12-31T19:26:16.000Z")

        XCTAssertNotEqual(nyanNyanTimeStamp, "秘密")
    }

    //v1.1の形。タイムラインのv2移行で、これはもう届かない
    func testFallsBackWhenTimeStampIsUnreadable() {
        let nyanNyanTimeStamp = PostedAtFormatter()
            .getNyanNyanTimeStamp(apiTimeStamp: "Fri Apr 03 10:12:54 +0000 2018")

        XCTAssertEqual(nyanNyanTimeStamp, "秘密")
    }
}
