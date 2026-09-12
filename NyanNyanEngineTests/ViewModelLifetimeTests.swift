//
//  ViewModelLifetimeTests.swift
//  NyanNyanEngineTests
//
//  Created by Tetsuya Nishikawa on 2026/09/08.
//  Copyright © 2026 Tetsuya Nishikawa. All rights reserved.
//

import XCTest
import RxSwift
import RxRelay
@testable import NyanNyanEngine

class ViewModelLifetimeTests: XCTestCase {

    private var tweetsRepository: StubTweetsRepository!
    private var authRepository: StubAuthRepository!
    private var loadingStatusRepository: StubLoadingStatusRepository!

    override func setUp() {
        super.setUp()
        tweetsRepository = StubTweetsRepository()
        authRepository = StubAuthRepository()
        loadingStatusRepository = StubLoadingStatusRepository()
    }

    func testPostNekogoViewModelIsReleasedWhenScreenGoesAway() {
        weak var released: PostNekogoViewModel?

        autoreleasepool {
            let viewModel = PostNekogoViewModel(tweetsRepository: tweetsRepository,
                                                authRepository: authRepository,
                                                loadingStatusRepository: loadingStatusRepository)
            released = viewModel
        }

        XCTAssertNil(released, "投稿画面のViewModelが解放されていない")
    }

    func testAccountViewModelIsReleasedWhenScreenGoesAway() {
        weak var released: AccountViewModel?

        autoreleasepool {
            let viewModel = AccountViewModel(authRepository: authRepository,
                                             tweetsRepository: tweetsRepository,
                                             loadingStatusRepository: LoadingStatusRepository.shared)
            released = viewModel
        }

        XCTAssertNil(released, "アカウント画面のViewModelが解放されていない")
    }

    //閉じた画面が購読を残すと、投稿1回でタイムラインの取得が残った数だけ走る。
    //取得はツイート1件あたりの従量課金のため、そのまま請求額に乗る
    func testDiscardedPostScreensDoNotRequestTimeline() {
        autoreleasepool {
            for _ in 0..<3 {
                _ = PostNekogoViewModel(tweetsRepository: tweetsRepository,
                                        authRepository: authRepository,
                                        loadingStatusRepository: loadingStatusRepository)
            }
        }

        tweetsRepository.emitPostedStatus("にゃーん🐾")

        XCTAssertEqual(tweetsRepository.refreshRequestCount, 0,
                       "閉じたはずの投稿画面がタイムラインを取りにいっている")
    }

    //生きている画面は反応する。上のテストが「誰も反応しない」だけで通ってしまうと、
    //購読が壊れていることを取り違えるため
    func testLivePostScreenRequestsTimelineOnce() {
        let viewModel = PostNekogoViewModel(tweetsRepository: tweetsRepository,
                                            authRepository: authRepository,
                                            loadingStatusRepository: loadingStatusRepository)

        tweetsRepository.emitPostedStatus("にゃーん🐾")

        XCTAssertEqual(tweetsRepository.refreshRequestCount, 1)
        XCTAssertNotNil(viewModel)
    }
}

private class StubTweetsRepository: BaseTweetsRepository {
    private let _postedStatus = PublishRelay<String?>()
    private(set) var refreshRequestCount = 0

    let nyanNyanStatuses: Observable<[NyanNyan]?> = Observable<[NyanNyan]?>.empty()
    let postedStatus: Observable<String?>
    let listScrollUpExecuted: Observable<Bool> = Observable<Bool>.empty()
    var buttonRefreshExecutedAt: AnyObserver<(() -> Void)>? = nil
    var pullToRefreshExecutedAt: AnyObserver<(() -> Void)>? = nil
    var nekogoToggleExecutedAt: AnyObserver<IndexPath>? = nil
    var postExecutedAs: AnyObserver<String?>? = nil

    init() {
        self.postedStatus = _postedStatus.asObservable()
        self.buttonRefreshExecutedAt = AnyObserver<(() -> Void)> { [weak self] _ in
            self?.refreshRequestCount += 1
        }
    }

    func emitPostedStatus(_ text: String?) {
        _postedStatus.accept(text)
    }
}

private class StubAuthRepository: BaseAuthRepository {
    let currentAccount: Observable<Account> = Observable<Account>.empty()
    let currentNyanNyanAccount: Observable<NyanNyanUser> = Observable<NyanNyanUser>.empty()
    var isLoggedIn: Observable<Bool>? = nil
    var logoutSucceeded: Observable<Bool>? = nil
    var accountUpdatedAt: AnyObserver<String>? = nil

    func updateNyanNyanAccount(postedText: String) { }

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

private class StubLoadingStatusRepository: BaseLoadingStatusRepository {
    let isLoading: Observable<Bool> = Observable<Bool>.empty()
    let loadingStatusChangedTo: AnyObserver<Bool> = AnyObserver<Bool> { _ in }
}
