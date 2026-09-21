//
//  TweetsRepositoryTests.swift
//  NyanNyanEngineTests
//
//  Created by Tetsuya Nishikawa on 2026/09/06.
//  Copyright © 2026 Tetsuya Nishikawa. All rights reserved.
//

import XCTest
import UIKit
import RxSwift
@testable import NyanNyanEngine

class TweetsRepositoryTests: XCTestCase {

    private var xAuthClient: StubXAuthClient!
    private var authRepository: StubAuthRepository!
    private var userDefaultsConnector: StubUserDefaultsConnector!
    private var repository: TweetsRepository!
    private var disposeBag = DisposeBag()

    //2026-08-30 に実際の POST /2/tweets から受け取った応答
    private let postedTweetJson = """
        {
            "data": {
                "edit_history_tweet_ids": [
                    ""
                ],
                "id": "2093888122887221687",
                "text": "にゃーん🐾"
            }
        }
        """

    //2026-09-21時点の公式スキーマから組み立てた応答。タイムライン取得は
    //1回叩くごとにXへの支払いが発生するため、形の確認のためだけには呼んでいない
    private let timelineJson = """
        {
            "data": [
                {
                    "created_at": "2019-12-15T12:00:00.000Z",
                    "id": "2093888122887221687",
                    "edit_history_tweet_ids": ["2093888122887221687"],
                    "text": "28日は、ちょーいい日で、めっちゃ笑って、水飲んで寝た",
                    "author_id": "1568466609035161600"
                }
            ],
            "includes": {
                "users": [
                    {
                        "id": "1568466609035161600",
                        "name": "nishik",
                        "username": "nishik75",
                        "profile_image_url": "https://pbs.twimg.com/profile_images/1568466676425039874/vCcKwevh_normal.png"
                    }
                ]
            }
        }
        """

    override func setUp() {
        super.setUp()
        xAuthClient = StubXAuthClient()
        authRepository = StubAuthRepository()
        //ログイン済みの状態から始めるのは、v2のホームタイムラインが
        //「誰の」タイムラインかをURLで名指しし、自分のIDが要るため
        userDefaultsConnector = StubUserDefaultsConnector(records: ["user_id": "1568466609035161600"])
        disposeBag = DisposeBag()
        //テストケースのプロパティで持つのは、ARCが「最後の使用」より先に
        //解放しうるため。ローカル変数へ束ねても生存はスコープ末尾まで保証されず、
        //解放されるとリポジトリのDisposeBagごと購読が外れて要求がどこへも流れない
        repository = TweetsRepository(userDefaultsConnector: userDefaultsConnector,
                                      xAuthClient: xAuthClient,
                                      authRepository: authRepository)
    }

    func testPostsToV2TweetsEndpoint() {
        xAuthClient.requestResult = .success(Data(postedTweetJson.utf8))

        repository.post(nekogo: "にゃーん🐾")

        let request = xAuthClient.executedRequests.first
        XCTAssertEqual(request?.url?.absoluteString, "https://api.x.com/2/tweets")
        XCTAssertEqual(request?.httpMethod, "POST")
        XCTAssertEqual(request?.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    //v1.1は本文をクエリへ載せていたため、JSON本体へ移ったことを固定しておく。
    //一致ではなく包含で見るのは、ハッシュタグ設定が本文の末尾へ足されるため
    func testCarriesNekogoInJsonBody() {
        xAuthClient.requestResult = .success(Data(postedTweetJson.utf8))

        repository.post(nekogo: "にゃーん🐾")

        guard let body = xAuthClient.executedRequests.first?.httpBody,
            let decoded = try? JSONDecoder().decode([String: String].self, from: body) else {
                return XCTFail("投稿本文がJSONとして読めなかった")
        }
        XCTAssertTrue(decoded["text"]?.contains("にゃーん🐾") ?? false)
    }

    //ポイントの根拠をXが返した本文に置くのは、送ろうとした猫語ではなく
    //Xに残った猫語で階級が決まるようにするため
    func testAwardsNekosanPointWithTextXKept() {
        xAuthClient.requestResult = .success(Data(postedTweetJson.utf8))

        repository.post(nekogo: "にゃーん🐾")

        XCTAssertEqual(authRepository.postedTexts, ["にゃーん🐾"])
    }

    //届かなかった猫語にポイントを払うと、投稿していない回数ぶん階級が上がり、
    //階級が投稿の記録として読めなくなる
    func testAwardsNoNekosanPointWhenPostFails() {
        xAuthClient.requestResult = .failure(.unauthorized)

        repository.post(nekogo: "にゃーん🐾")

        XCTAssertTrue(authRepository.postedTexts.isEmpty)
    }

    //2026-09-06 時点の公式スキーマでは text は必須だが、v2は値を持たない属性を
    //応答へ書かない規約のため、応答の形は将来も動きうる。1つ欠けただけで
    //デコードは丸ごと失敗するので、投稿が成立した事実まで巻き添えにすると、
    //Xには猫語が残ったのに階級だけ据え置かれる
    func testAwardsNekosanPointWhenResponseLacksText() {
        let textlessJson = """
            {
                "data": {
                    "id": "2093888122887221687"
                }
            }
            """
        xAuthClient.requestResult = .success(Data(textlessJson.utf8))

        repository.post(nekogo: "にゃーん🐾")

        XCTAssertTrue(authRepository.postedTexts.first?.contains("にゃーん🐾") ?? false)
    }

    //応答をまったく読めなかったときも、Xが受け取った事実はHTTPの成否が示している
    func testAwardsNekosanPointFromSentNekogoWhenResponseIsUnreadable() {
        xAuthClient.requestResult = .success(Data("{}".utf8))

        repository.post(nekogo: "にゃーん🐾")

        XCTAssertEqual(authRepository.postedTexts.count, 1)
        XCTAssertTrue(authRepository.postedTexts.first?.contains("にゃーん🐾") ?? false)
    }

    //2つの更新の違いは先頭へ戻すかどうかだけのため、両方向を固定しておく。
    //どちらかへ倒れていると、引っ張って更新のたびに見ていた位置を失う
    func testScrollsListToTopWhenAsked() {
        var scrolledToTop = false
        repository.listScrollUpExecuted
            .subscribe(onNext: { _ in scrolledToTop = true })
            .disposed(by: disposeBag)

        repository.refreshTimeline(scrollingToTop: true) { }

        XCTAssertTrue(scrolledToTop)
    }

    func testKeepsListPositionWhenNotAsked() {
        var scrolledToTop = false
        repository.listScrollUpExecuted
            .subscribe(onNext: { _ in scrolledToTop = true })
            .disposed(by: disposeBag)

        repository.refreshTimeline(scrollingToTop: false) { }

        XCTAssertFalse(scrolledToTop)
    }

    //v1.1のホームタイムラインは2026年に廃止されている。取得先が移ったことと、
    //何件ぶん支払うかを、URLの一致で固定しておく
    func testFetchesTimelineFromV2Endpoint() {
        xAuthClient.requestResult = .success(Data(timelineJson.utf8))

        repository.refreshTimeline(scrollingToTop: false) { }

        let request = xAuthClient.executedRequests.first
        XCTAssertEqual(request?.url?.absoluteString,
                       "https://api.x.com/2/users/1568466609035161600/timelines/reverse_chronological"
                        + "?max_results=10"
                        + "&tweet.fields=created_at,author_id"
                        + "&expansions=author_id"
                        + "&user.fields=name,username,profile_image_url")
        XCTAssertEqual(request?.httpMethod, "GET")
    }

    //v2はツイートと投稿者を別の場所へ返すため、突き合わせて初めて
    //一覧の1行が揃う。v1.1では1件の中に投稿者が入っていた
    func testComposesNyanNyanFromPostAndItsAuthor() {
        xAuthClient.requestResult = .success(Data(timelineJson.utf8))
        var received: [NyanNyan]? = nil

        repository.nyanNyanStatuses
            .subscribe(onNext: { received = $0 })
            .disposed(by: disposeBag)
        repository.refreshTimeline(scrollingToTop: false) { }

        XCTAssertEqual(received?.count, 1)
        XCTAssertEqual(received?.first?.id, "2093888122887221687")
        XCTAssertEqual(received?.first?.userName, "nishik")
        XCTAssertEqual(received?.first?.userId, "nishik75")
        XCTAssertEqual(received?.first?.ningengo, "28日は、ちょーいい日で、めっちゃ笑って、水飲んで寝た")
        //時刻の言い回しをOSが決めるため、読めたかどうかだけを見る。
        //言い回しを固定すると、端末の言語でも、時が経つだけでも落ちる
        XCTAssertNotEqual(received?.first?.nyanedAt, "秘密")
    }

    //高解像度版へ読み替える処理がUserへ1本化されたことを確かめる。
    //v1.1の頃は同じ書き換えがStatusの中にも居た
    func testReadsAuthorImageAtFineResolution() {
        xAuthClient.requestResult = .success(Data(timelineJson.utf8))
        var received: [NyanNyan]? = nil

        repository.nyanNyanStatuses
            .subscribe(onNext: { received = $0 })
            .disposed(by: disposeBag)
        repository.refreshTimeline(scrollingToTop: false) { }

        XCTAssertEqual(received?.first?.profileUrl,
                       "https://pbs.twimg.com/profile_images/1568466676425039874/vCcKwevh.png")
    }

    //既定値で埋めると、名前の欄がにゃんにゃ先生で埋まり、先生が言っていない
    //ことを言ったことになる。出せないものは出さない。
    //引き当てられる投稿を同じ応答へ混ぜているのは、空になったことだけを見ると
    //「落とした」のか「応答を読めなかった」のか区別がつかず、
    //取得そのものが壊れていても通るテストになるため
    func testDropsOnlyThePostWhoseAuthorIsMissing() {
        let halfAuthorlessJson = """
            {
                "data": [
                    {
                        "created_at": "2019-12-15T12:00:00.000Z",
                        "id": "2093888122887221687",
                        "text": "28日は、ちょーいい日で、めっちゃ笑って、水飲んで寝た",
                        "author_id": "9999999999999999999"
                    },
                    {
                        "created_at": "2019-12-15T12:00:00.000Z",
                        "id": "2093888122887221688",
                        "text": "にゃーん🐾",
                        "author_id": "1568466609035161600"
                    }
                ],
                "includes": {
                    "users": [
                        {
                            "id": "1568466609035161600",
                            "name": "nishik",
                            "username": "nishik75"
                        }
                    ]
                }
            }
            """
        xAuthClient.requestResult = .success(Data(halfAuthorlessJson.utf8))
        var received: [NyanNyan]? = nil

        repository.nyanNyanStatuses
            .subscribe(onNext: { received = $0 })
            .disposed(by: disposeBag)
        repository.refreshTimeline(scrollingToTop: false) { }

        XCTAssertEqual(received?.count, 1)
        XCTAssertEqual(received?.first?.id, "2093888122887221688")
        XCTAssertEqual(received?.first?.userName, "nishik")
    }

    //未ログインでXを叩かないのは、通らない要求であるうえ、読み取りが
    //取得したツイート1件ごとの課金であるため
    func testShowsSenseiWithoutAskingXWhenNotLoggedIn() {
        userDefaultsConnector.records.removeValue(forKey: "user_id")
        var received: [NyanNyan]? = nil

        repository.nyanNyanStatuses
            .subscribe(onNext: { received = $0 })
            .disposed(by: disposeBag)
        repository.refreshTimeline(scrollingToTop: false) { }

        XCTAssertTrue(xAuthClient.executedRequests.isEmpty)
        XCTAssertEqual(received?.first?.userName, R.string.stringValues.default_user_name())
    }

    //v2移行で取得が同期から非同期になった。終わりを告げるのが応答より先だと、
    //画面は取得中のまま次の操作を受け付ける
    func testNotifiesFinishedOnlyAfterXAnswers() {
        xAuthClient.requestResult = .success(Data(timelineJson.utf8))
        xAuthClient.holdsResponse = true
        var finished = false

        repository.refreshTimeline(scrollingToTop: false) { finished = true }
        XCTAssertFalse(finished)

        xAuthClient.deliverHeldResponse()
        XCTAssertTrue(finished)
    }

    //知らせないままだと、画面が終わりを待ち続けてインジケータが回り続ける
    func testNotifiesFinishedWhenFetchFails() {
        xAuthClient.requestResult = .failure(.rateLimited)
        var finished = false

        repository.refreshTimeline(scrollingToTop: false) { finished = true }

        XCTAssertTrue(finished)
    }

    //読めなかったことを空の画面として見せると、ねこさんが居なくなったように見える
    func testKeepsNekosanOnScreenWhenFetchFails() {
        xAuthClient.requestResult = .success(Data(timelineJson.utf8))
        var received: [NyanNyan]? = nil

        repository.nyanNyanStatuses
            .subscribe(onNext: { received = $0 })
            .disposed(by: disposeBag)
        repository.refreshTimeline(scrollingToTop: false) { }

        xAuthClient.requestResult = .failure(.serverError)
        repository.refreshTimeline(scrollingToTop: false) { }

        XCTAssertEqual(received?.first?.userName, "nishik")
    }

    //投稿欄へ返すのは利用者が打った猫語。Xが返した本文には
    //ハッシュタグ設定が足されており、打った内容と一致しない
    func testNotifiesNekogoTheUserTyped() {
        xAuthClient.requestResult = .success(Data(postedTweetJson.utf8))
        var received: String? = nil

        repository.postedStatus
            .subscribe(onNext: { received = $0 })
            .disposed(by: disposeBag)
        repository.post(nekogo: "にゃーん🐾")

        XCTAssertEqual(received, "にゃーん🐾")
    }

    //失敗をnilで伝える。本文を流すと、画面は獲得していないポイント額を
    //「獲得した」と告げ、表示とFirestoreの値が食い違う
    func testNotifiesNothingWhenPostFails() {
        xAuthClient.requestResult = .failure(.forbidden)
        var received: String? = "初期値のまま流れてこないことを見分けるための値"

        repository.postedStatus
            .subscribe(onNext: { received = $0 })
            .disposed(by: disposeBag)
        repository.post(nekogo: "にゃーん🐾")

        XCTAssertNil(received)
    }
}

private class StubXAuthClient: BaseXAuthClient {
    var requestResult: Result<Data, ApiError> = .failure(.noResponse)
    var executedRequests: [URLRequest] = []
    //応答を手元で止められるようにしているのは、v2移行で取得が同期から
    //非同期になり、「いつ終わったことになるか」が初めて意味を持つため
    var holdsResponse = false
    private var heldObservers: [AnyObserver<Result<Data, ApiError>>] = []

    func authorize(presenter: AuthorizationSheetPresenter, completion: @escaping ((Bool) -> Void)) {
        completion(true)
    }

    func executeAuthorizedRequest(urlRequest: URLRequest) -> Observable<Result<Data, ApiError>> {
        executedRequests.append(urlRequest)
        guard holdsResponse else { return Observable<Result<Data, ApiError>>.just(requestResult) }
        return Observable<Result<Data, ApiError>>.create { [weak self] observer in
            self?.heldObservers.append(observer)
            return Disposables.create()
        }
    }

    func deliverHeldResponse() {
        let observers = heldObservers
        heldObservers = []
        observers.forEach {
            $0.onNext(requestResult)
            $0.onCompleted()
        }
    }

    func resumeAuthorization(with url: URL) -> Bool {
        return false
    }

    func revokeSession() -> Observable<Bool> {
        return Observable<Bool>.just(true)
    }

    func discardSession() { }

    func hasAuthorizedSession() -> Bool {
        return true
    }
}

private class StubAuthRepository: BaseAuthRepository {
    var postedTexts: [String] = []

    let currentAccount: Observable<Account> = Observable<Account>.empty()
    let currentNyanNyanAccount: Observable<NyanNyanUser> = Observable<NyanNyanUser>.empty()
    var isLoggedIn: Observable<Bool>? = nil
    var logoutSucceeded: Observable<Bool>? = nil

    func reloadAccount() { }

    func updateNyanNyanAccount(postedText: String) {
        postedTexts.append(postedText)
    }

    func beginAuthorization(presenter: AuthorizationSheetPresenter,
                            modelUpdateLogic: @escaping (() -> Void)) { }

    func resumeAuthorization(with url: URL) -> Bool {
        return false
    }

    func authAppUser() { }

    func invalidateAccountInfo(modelUpdateLogic: @escaping (() -> Void)) -> Observable<Bool> {
        return Observable<Bool>.just(true)
    }

    func getLoggedInStatus() -> Bool {
        return true
    }

    func useMultiplierValue(completion: @escaping ((Int) -> Void)) {
        completion(1)
    }
}

private class StubUserDefaultsConnector: BaseUserDefaultsConnector {
    var records: [String: String]

    init(records: [String: String] = [:]) {
        self.records = records
    }

    func registerString(key: String, value: String) {
        records[key] = value
    }

    func getString(withKey key: String) -> String? {
        return records[key]
    }

    func isRegistered(withKey key: String) -> Bool {
        return records[key] != nil
    }

    func deleteRecord(forKey key: String) {
        records.removeValue(forKey: key)
    }
}
