//
//  AuthRepositoryTests.swift
//  NyanNyanEngineTests
//
//  Created by Tetsuya Nishikawa on 2026/09/01.
//  Copyright © 2026 Tetsuya Nishikawa. All rights reserved.
//

import XCTest
import RxSwift
@testable import NyanNyanEngine

class AuthRepositoryTests: XCTestCase {

    private var xAuthClient: StubXAuthClient!
    private var disposeBag = DisposeBag()

    //アイコンを設定していないアカウントの応答。profile_image_url が省かれる
    private let myAccountWithoutImageJson = """
        {
            "data": {
                "id": "1568466609035161600",
                "name": "nishik",
                "username": "nishik75"
            }
        }
        """

    //2026-08-30 に実際の GET /2/users/me から受け取った応答
    private let myAccountJson = """
        {
            "data": {
                "id": "1568466609035161600",
                "name": "nishik",
                "profile_image_url": "https://pbs.twimg.com/profile_images/1568466676425039874/vCcKwevh_normal.png",
                "username": "nishik75"
            }
        }
        """

    private let oauth1Records = ["oauth_token": "ふるいとーくん",
                                 "oauth_token_secret": "ふるいひみつ",
                                 "user_id": "1568466609035161600",
                                 "screen_name": "nishik75",
                                 "name": "nishik",
                                 "profile_image_url_https": "https://pbs.twimg.com/profile_images/vCcKwevh_normal.png"]

    override func setUp() {
        super.setUp()
        xAuthClient = StubXAuthClient()
        disposeBag = DisposeBag()
    }

    //OAuth 1.0aのトークンが残ったままだと、死んだv1.1のエンドポイントを
    //叩き続ける状態のまま起動してしまう
    func testDiscardsOAuth1CredentialsOnLaunch() {
        let userDefaultsConnector = StubUserDefaultsConnector(records: oauth1Records)

        _ = createRepository(userDefaultsConnector: userDefaultsConnector)

        XCTAssertTrue(userDefaultsConnector.records.isEmpty)
    }

    //OAuth 2.0でログイン済みのアカウント情報まで消さないことが、
    //起動のたびにログインし直さずに済む前提になっている
    func testKeepsAccountInfoWhenNoOAuth1CredentialsRemain() {
        let records = ["user_id": "1568466609035161600",
                       "screen_name": "nishik75",
                       "name": "nishik"]
        let userDefaultsConnector = StubUserDefaultsConnector(records: records)

        _ = createRepository(userDefaultsConnector: userDefaultsConnector)

        XCTAssertEqual(userDefaultsConnector.records, records)
    }

    //目印になるOAuth 1.0aの認証情報を最後に消す。先に消すと、途中で終了した
    //ときに目印だけが失われ、残りを消しそびれたまま次の起動を迎える
    func testDiscardsOAuth1CredentialsLastSoInterruptionCanRetry() {
        let userDefaultsConnector = StubUserDefaultsConnector(records: oauth1Records)

        _ = createRepository(userDefaultsConnector: userDefaultsConnector)

        XCTAssertEqual(userDefaultsConnector.deletedKeys.suffix(2),
                       ["oauth_token", "oauth_token_secret"])
    }

    func testLoggedInStatusFollowsAuthorizedSession() {
        xAuthClient.hasSession = true
        XCTAssertTrue(createRepository().getLoggedInStatus())

        xAuthClient.hasSession = false
        XCTAssertFalse(createRepository().getLoggedInStatus())
    }

    func testLoginStoresAccountInfoAndUpdatesModel() {
        xAuthClient.requestResult = .success(Data(myAccountJson.utf8))
        let userDefaultsConnector = StubUserDefaultsConnector()
        let repository = createRepository(userDefaultsConnector: userDefaultsConnector)
        var modelUpdated = false

        repository.beginAuthorization(presenter: StubAuthorizationSheetPresenter()) { modelUpdated = true }

        XCTAssertTrue(modelUpdated)
        XCTAssertTrue(repository.getLoggedInStatus())
        //user_idはにゃんにゃんポイントのドキュメントキーの素材になる
        XCTAssertEqual(userDefaultsConnector.records["user_id"], "1568466609035161600")
        XCTAssertEqual(userDefaultsConnector.records["screen_name"], "nishik75")
        XCTAssertEqual(userDefaultsConnector.records["name"], "nishik")
        XCTAssertEqual(userDefaultsConnector.records["profile_image_url_https"],
                       "https://pbs.twimg.com/profile_images/1568466676425039874/vCcKwevh_normal.png")
    }

    func testLoginAsksForMyAccountOfV2() {
        xAuthClient.requestResult = .success(Data(myAccountJson.utf8))

        createRepository().beginAuthorization(presenter: StubAuthorizationSheetPresenter()) { }

        XCTAssertEqual(xAuthClient.executedRequests.first?.url?.absoluteString,
                       "https://api.x.com/2/users/me?user.fields=profile_image_url")
    }

    //アイコンを持たない利用者が、ログインしても既定のアカウント表示から
    //抜けられなくなることがあった。アイコンの有無で表示が止まらないことを固定する
    func testShowsAccountEvenWithoutProfileImage() {
        xAuthClient.requestResult = .success(Data(myAccountWithoutImageJson.utf8))
        xAuthClient.hasSession = true
        let userDefaultsConnector = StubUserDefaultsConnector()
        let repository = createRepository(userDefaultsConnector: userDefaultsConnector)
        var received: Account? = nil

        repository.beginAuthorization(presenter: StubAuthorizationSheetPresenter()) { }
        repository.currentAccount
            .subscribe(onNext: { received = $0 })
            .disposed(by: disposeBag)
        repository.accountUpdatedAt?.onNext("")

        XCTAssertEqual(received?.user.username, "nishik75")
        XCTAssertNil(received?.user.profileImageUrl)
        XCTAssertFalse(received?.isDefaultAccount() ?? true)
    }

    //認可画面を閉じただけのときに画面が動くと、利用者にとっては
    //何も操作していないのに勝手に更新が始まったように見える
    func testCancelledLoginChangesNothing() {
        xAuthClient.authorizeResult = false
        let repository = createRepository()
        var modelUpdated = false

        repository.beginAuthorization(presenter: StubAuthorizationSheetPresenter()) { modelUpdated = true }

        XCTAssertFalse(modelUpdated)
        XCTAssertFalse(repository.getLoggedInStatus())
        XCTAssertTrue(xAuthClient.executedRequests.isEmpty)
    }

    //401が返るということはX側で連携が切れている。端末側を残すと
    //ログイン表示のまま何も取得できない状態が続く
    func testDiscardsSessionWhenXAnswersUnauthorized() {
        xAuthClient.requestResult = .failure(.unauthorized)
        let userDefaultsConnector = StubUserDefaultsConnector(records: oauth1Records)
        let repository = createRepository(userDefaultsConnector: userDefaultsConnector)

        repository.beginAuthorization(presenter: StubAuthorizationSheetPresenter()) { }

        XCTAssertFalse(repository.getLoggedInStatus())
        XCTAssertTrue(userDefaultsConnector.records.isEmpty)
    }

    func testLogoutClearsAccountEvenWhenRevokeFails() {
        xAuthClient.hasSession = true
        xAuthClient.revokeResult = false
        let userDefaultsConnector = StubUserDefaultsConnector(records: oauth1Records)
        let repository = createRepository(userDefaultsConnector: userDefaultsConnector)
        var modelUpdated = false
        var logoutSucceeded = false

        repository.logoutSucceeded?
            .subscribe(onNext: { logoutSucceeded = $0 })
            .disposed(by: disposeBag)
        repository.invalidateAccountInfo { modelUpdated = true }
            .subscribe()
            .disposed(by: disposeBag)

        XCTAssertTrue(logoutSucceeded)
        XCTAssertTrue(modelUpdated)
        XCTAssertFalse(repository.getLoggedInStatus())
        XCTAssertTrue(userDefaultsConnector.records.isEmpty)
    }

    //OS経由で届いた戻り先URLが、進行中の認可まで素通しで届くこと
    func testPassesCallbackUrlToAuthorization() {
        let repository = createRepository()
        let callbackUrl = URL(string: "com.ntetz.ios.nyannyanengine-d://callback?code=にゃんこーど")!

        XCTAssertTrue(repository.resumeAuthorization(with: callbackUrl))

        XCTAssertEqual(xAuthClient.resumedUrls, [callbackUrl])
    }

    //FirebaseClientを実物のまま渡しているのは、ここで確かめる経路が
    //Firestoreへ触れず、initも接続を張らないため
    private func createRepository(userDefaultsConnector: BaseUserDefaultsConnector = StubUserDefaultsConnector()) -> AuthRepository {
        return AuthRepository(firebaseClient: FirebaseClient.shared,
                              userDefaultsConnector: userDefaultsConnector,
                              xAuthClient: xAuthClient)
    }
}

private class StubAuthorizationSheetPresenter: AuthorizationSheetPresenter {
    let viewControllerForAuthorizationSheet = UIViewController()
}

private class StubXAuthClient: BaseXAuthClient {
    var hasSession = false
    var authorizeResult = true
    var revokeResult = true
    var requestResult: Result<Data, ApiError> = .failure(.noResponse)
    var resumeResult = true
    var executedRequests: [URLRequest] = []
    var resumedUrls: [URL] = []

    func authorize(presenter: AuthorizationSheetPresenter, completion: @escaping ((Bool) -> Void)) {
        hasSession = authorizeResult
        completion(authorizeResult)
    }

    func resumeAuthorization(with url: URL) -> Bool {
        resumedUrls.append(url)
        return resumeResult
    }

    func executeAuthorizedRequest(urlRequest: URLRequest) -> Observable<Result<Data, ApiError>> {
        executedRequests.append(urlRequest)
        return Observable<Result<Data, ApiError>>.just(requestResult)
    }

    func revokeSession() -> Observable<Bool> {
        discardSession()
        return Observable<Bool>.just(revokeResult)
    }

    func discardSession() {
        hasSession = false
    }

    func hasAuthorizedSession() -> Bool {
        return hasSession
    }
}

private class StubUserDefaultsConnector: BaseUserDefaultsConnector {
    var records: [String: String]
    var deletedKeys: [String] = []

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
        deletedKeys.append(key)
        records.removeValue(forKey: key)
    }
}
