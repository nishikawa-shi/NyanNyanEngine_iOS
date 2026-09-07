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
    //TODO: 後々、日付型っぽいやつにする
    //提示元を受け取るのは、認可シートを出すのに提示元の画面が要るため
    var authExecutedAt: AnyObserver<AuthorizationSheetPresenter>? { get }
    var buttonRefreshExecutedAt: AnyObserver<String>? { get }
    //引っ張って更新だけが「終わったこと」を受け取るのは、止める部品が
    //画面ごとに違い、いつ止めるかを決められるのが画面の側だけのため
    var pullToRefreshExecutedAt: AnyObserver<(() -> Void)>? { get }
    var cellTapExecutedOn: AnyObserver<IndexPath>? { get }
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

    var authExecutedAt: AnyObserver<AuthorizationSheetPresenter>? = nil
    var buttonRefreshExecutedAt: AnyObserver<String>? = nil
    var pullToRefreshExecutedAt: AnyObserver<(() -> Void)>? = nil
    var cellTapExecutedOn: AnyObserver<IndexPath>? = nil
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

        //weakにしているのは、渡す先のリポジトリがシングルトンで、画面と一緒に
        //消えるこのクラスを掴んだまま応答を待ててしまうため
        self.buttonRefreshExecutedAt = AnyObserver<String>() { [weak self] updatedAt in
            guard let self = self else { return }
            self.loadingStatusRepository
                .loadingStatusChangedTo
                .onNext(true)

            self.authRepository
                .accountUpdatedAt?
                .onNext(updatedAt.element ?? "")

            self.tweetsRepository
                .buttonRefreshExecutedAt?
                .onNext() { [weak self] in
                    self?.loadingStatusRepository.loadingStatusChangedTo.onNext(false)
            }
        }

        self.pullToRefreshExecutedAt = AnyObserver<(() -> Void)>() { [weak self] notifyFinished in
            guard let self = self, let notifyFinished = notifyFinished.element else { return }
            self.authRepository
                .accountUpdatedAt?
                .onNext("")

            self.tweetsRepository
                .pullToRefreshExecutedAt?
                .onNext(notifyFinished)
        }

        self.cellTapExecutedOn = AnyObserver<IndexPath>() { [weak self] in
            guard let self = self, let index = $0.element else { return }
            self.tweetsRepository
                .nekogoToggleExecutedAt?
                .onNext(index)
        }

        self.authExecutedAt = AnyObserver<AuthorizationSheetPresenter>() { [weak self] event in
            guard let self = self, let presenter = event.element else { return }
            self.authRepository.beginAuthorization(presenter: presenter) { [weak self] in
                //ログイン直後の更新をボタン更新と同じ経路へ載せるのは、アカウントと
                //タイムラインの取り直し、ローディングの解除が既に揃っているため
                self?.buttonRefreshExecutedAt?.onNext("0000/01/01 00:00:00")
            }
        }
    }

    func useMultiplierValue(completion: @escaping ((Int) -> Void)) {
        self.authRepository.useMultiplierValue(completion: completion)
    }
}
