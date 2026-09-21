//
//  HomeTimelineViewModel.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/04/30.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation
import RxSwift

protocol HomeTimelineViewModelInput: AnyObject {
    //提示元を受け取るのは、認可シートを出すのに提示元の画面が要るため
    func beginAuthorization(presenter: AuthorizationSheetPresenter)
    func refresh()
    //引っ張って更新だけが「終わったこと」を受け取るのは、止める部品が
    //画面ごとに違い、いつ止めるかを決められるのが画面の側だけのため
    func refreshByPull(notifying notifyFinished: @escaping (() -> Void))
    func toggleNekogo(at indexPath: IndexPath)
    func useMultiplierValue(completion: @escaping ((Int)->Void))
}

protocol HomeTimelineViewModelOutput: AnyObject {
    var nyanNyanStatuses: Observable<[NyanNyan]?> { get }
    var listScrollUpExecuted: Observable<Bool> { get }
    var currentAccount: Observable<Account> { get }
    var isLoading: Observable<Bool> { get }
    var isLoggedIn: Observable<Bool>? { get }
    var postSucceeded: Observable<String?> { get }
}

final class HomeTimelineViewModel: HomeTimelineViewModelInput, HomeTimelineViewModelOutput {
    private let tweetsRepository: BaseTweetsRepository
    private let authRepository: BaseAuthRepository
    private let loadingStatusRepository: BaseLoadingStatusRepository
    private let disposeBag = DisposeBag()

    let currentAccount: Observable<Account>
    let nyanNyanStatuses: Observable<[NyanNyan]?>
    let listScrollUpExecuted: Observable<Bool>
    let isLoading: Observable<Bool>
    let isLoggedIn: Observable<Bool>?
    let postSucceeded: Observable<String?>

    init(tweetsRepository: BaseTweetsRepository = TweetsRepository.shared,
         authRepository: BaseAuthRepository = AuthRepository.shared,
         loadingStatusRepository: BaseLoadingStatusRepository = LoadingStatusRepository.shared) {
        self.tweetsRepository = tweetsRepository
        self.authRepository = authRepository
        self.loadingStatusRepository = loadingStatusRepository

        self.currentAccount = authRepository.currentAccount
        self.nyanNyanStatuses = tweetsRepository.nyanNyanStatuses
        self.listScrollUpExecuted = tweetsRepository.listScrollUpExecuted
        self.isLoading = loadingStatusRepository.isLoading
        self.isLoggedIn = authRepository.isLoggedIn
        self.postSucceeded = tweetsRepository.postedStatus.map {
            guard let text = $0 else { return nil }
            return [text, R.string.stringValues.post_original_text()].joined()
        }
    }

    func beginAuthorization(presenter: AuthorizationSheetPresenter) {
        self.authRepository.beginAuthorization(presenter: presenter) { [weak self] in
            //ログイン直後の更新をボタン更新と同じ経路へ載せるのは、アカウントと
            //タイムラインの取り直し、ローディングの解除が既に揃っているため
            self?.refresh()
        }
    }

    func refresh() {
        self.loadingStatusRepository
            .loadingStatusChangedTo
            .onNext(true)

        self.authRepository.reloadAccount()

        //消灯の知らせを先に取り出してから渡すのは、取得が終わる前にこの画面が
        //解放されると取りこぼし、共有のインジケータが回ったままになるため
        let loadingStatusRepository = self.loadingStatusRepository
        self.tweetsRepository.refreshTimeline(scrollingToTop: true) {
            loadingStatusRepository.loadingStatusChangedTo.onNext(false)
        }
    }

    func refreshByPull(notifying notifyFinished: @escaping (() -> Void)) {
        self.authRepository.reloadAccount()
        self.tweetsRepository.refreshTimeline(scrollingToTop: false, notifying: notifyFinished)
    }

    func toggleNekogo(at indexPath: IndexPath) {
        self.tweetsRepository.toggleNekogo(at: indexPath)
    }

    func useMultiplierValue(completion: @escaping ((Int) -> Void)) {
        self.authRepository.useMultiplierValue(completion: completion)
    }
}
