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

    override func setUp() {
        super.setUp()
        xAuthClient = StubXAuthClient()
        authRepository = StubAuthRepository()
        disposeBag = DisposeBag()
    }

    func testPostsToV2TweetsEndpoint() {
        xAuthClient.requestResult = .success(Data(postedTweetJson.utf8))

        createRepository().postExecutedAs?.onNext("にゃーん🐾")

        let request = xAuthClient.executedRequests.first
        XCTAssertEqual(request?.url?.absoluteString, "https://api.x.com/2/tweets")
        XCTAssertEqual(request?.httpMethod, "POST")
        XCTAssertEqual(request?.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    //v1.1は本文をクエリへ載せていたため、JSON本体へ移ったことを固定しておく。
    //一致ではなく包含で見るのは、ハッシュタグ設定が本文の末尾へ足されるため
    func testCarriesNekogoInJsonBody() {
        xAuthClient.requestResult = .success(Data(postedTweetJson.utf8))

        createRepository().postExecutedAs?.onNext("にゃーん🐾")

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

        createRepository().postExecutedAs?.onNext("にゃーん🐾")

        XCTAssertEqual(authRepository.postedTexts, ["にゃーん🐾"])
    }

    //届かなかった猫語にポイントを払うと、投稿していない回数ぶん階級が上がり、
    //階級が投稿の記録として読めなくなる
    func testAwardsNoNekosanPointWhenPostFails() {
        xAuthClient.requestResult = .failure(.unauthorized)

        createRepository().postExecutedAs?.onNext("にゃーん🐾")

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

        createRepository().postExecutedAs?.onNext("にゃーん🐾")

        XCTAssertTrue(authRepository.postedTexts.first?.contains("にゃーん🐾") ?? false)
    }

    //応答をまったく読めなかったときも、Xが受け取った事実はHTTPの成否が示している
    func testAwardsNekosanPointFromSentNekogoWhenResponseIsUnreadable() {
        xAuthClient.requestResult = .success(Data("{}".utf8))

        createRepository().postExecutedAs?.onNext("にゃーん🐾")

        XCTAssertEqual(authRepository.postedTexts.count, 1)
        XCTAssertTrue(authRepository.postedTexts.first?.contains("にゃーん🐾") ?? false)
    }

    //投稿欄へ返すのは利用者が打った猫語。Xが返した本文には
    //ハッシュタグ設定が足されており、打った内容と一致しない
    func testNotifiesNekogoTheUserTyped() {
        xAuthClient.requestResult = .success(Data(postedTweetJson.utf8))
        let repository = createRepository()
        var received: String? = nil

        repository.postedStatus
            .subscribe(onNext: { received = $0 })
            .disposed(by: disposeBag)
        repository.postExecutedAs?.onNext("にゃーん🐾")

        XCTAssertEqual(received, "にゃーん🐾")
    }

    //ApiClientとUserDefaultsを実物のまま渡しているのは、ここで確かめる投稿の
    //経路がXAuthClient側を通り、どちらにも触れないため
    private func createRepository() -> TweetsRepository {
        return TweetsRepository(apiClient: ApiClient.shared,
                                userDefaultsConnector: UserDefaultsConnector.shared,
                                xAuthClient: xAuthClient,
                                authRepository: authRepository)
    }
}

private class StubXAuthClient: BaseXAuthClient {
    var requestResult: Result<Data, ApiError> = .failure(.noResponse)
    var executedRequests: [URLRequest] = []

    func authorize(presenter: AuthorizationSheetPresenter, completion: @escaping ((Bool) -> Void)) {
        completion(true)
    }

    func executeAuthorizedRequest(urlRequest: URLRequest) -> Observable<Result<Data, ApiError>> {
        executedRequests.append(urlRequest)
        return Observable<Result<Data, ApiError>>.just(requestResult)
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
    var accountUpdatedAt: AnyObserver<String>? = nil

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
