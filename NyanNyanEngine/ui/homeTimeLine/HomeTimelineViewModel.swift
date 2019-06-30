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
    var authExecutedAt: AnyObserver<String>? { get }
    var buttonRefreshExecutedAt: AnyObserver<String>? { get }
    var pullToRefreshExecutedAt: AnyObserver<UIRefreshControl>? { get }
    var infiniteScrollExecutedAt: AnyObserver<String>? { get }
    var cellTapExecutedOn: AnyObserver<IndexPath>? { get }
}

protocol HomeTimelineViewModelOutput: AnyObject {
    var nyanNyanStatuses: Observable<[NyanNyan]?> { get }
    var currentUser: Observable<String> { get }
    var isLoading: Observable<Bool> { get }
    var isInfiniteLoading: Observable<Bool> { get }
    var isLoggedIn: Observable<Bool>? { get }
    var authPageUrl: Observable<URL?>? { get }
    var postSucceeded: Observable<String?> { get }
}

final class HomeTimelineViewModel: HomeTimelineViewModelInput, HomeTimelineViewModelOutput {
    private let tweetsRepository: BaseTweetsRepository
    private let authRepository: BaseAuthRepository
    private let loadingStatusRepository: BaseLoadingStatusRepository
    private let disposeBag = DisposeBag()
    
    var authExecutedAt: AnyObserver<String>? = nil
    var buttonRefreshExecutedAt: AnyObserver<String>? = nil
    var pullToRefreshExecutedAt: AnyObserver<UIRefreshControl>? = nil
    var infiniteScrollExecutedAt: AnyObserver<String>? = nil
    var cellTapExecutedOn: AnyObserver<IndexPath>? = nil
    let currentUser: Observable<String>
    let nyanNyanStatuses: Observable<[NyanNyan]?>
    let isLoading: Observable<Bool>
    let isInfiniteLoading: Observable<Bool>
    let isLoggedIn: Observable<Bool>?
    let authPageUrl: Observable<URL?>?
    let postSucceeded: Observable<String?>
    
    init(tweetsRepository: BaseTweetsRepository = TweetsRepository.shared,
         authRepository: BaseAuthRepository = AuthRepository.shared,
         loadingStatusRepository: BaseLoadingStatusRepository = LoadingStatusRepository.shared) {
        self.tweetsRepository = tweetsRepository
        self.authRepository = authRepository
        self.loadingStatusRepository = loadingStatusRepository
        
        self.currentUser = authRepository.currentUser
        self.nyanNyanStatuses = tweetsRepository.nyanNyanStatuses
        self.isLoading = loadingStatusRepository.isLoading
        self.isInfiniteLoading = loadingStatusRepository.isInfiniteLoading
        self.isLoggedIn = authRepository.isLoggedIn
        self.authPageUrl = authRepository.authPageUrl
        self.postSucceeded = tweetsRepository.postedStatus.map {
            guard let text = $0?.text else { return nil }
            return [text, R.string.stringValues.post_original_text()].joined()
        }
        
        self.buttonRefreshExecutedAt = AnyObserver<String>() { [unowned self] updatedAt in
            self.loadingStatusRepository
                .loadingStatusChangedTo
                .onNext(true)
            
            self.authRepository
                .loginExecutedAt?
                .onNext(updatedAt.element ?? "")
            
            self.tweetsRepository
                .buttonRefreshExecutedAt?
                .onNext() { self.loadingStatusRepository.loadingStatusChangedTo.onNext(false) }
        }
        
        self.pullToRefreshExecutedAt = AnyObserver<UIRefreshControl>() { [unowned self] uiRefreshControl in
            self.authRepository
                .loginExecutedAt?
                .onNext("")
            
            self.tweetsRepository
                .pullToRefreshExecutedAt?
                .onNext(uiRefreshControl.element)
        }
        
        self.infiniteScrollExecutedAt = AnyObserver<String>() { [unowned self] res in
            self.loadingStatusRepository
                .infiniteLoadingStatusChangedTo
                .onNext(true)
        }
        
        self.cellTapExecutedOn = AnyObserver<IndexPath>() { [unowned self] in
            guard let index = $0.element else { return }
            switch(index.section) {
            case 0:
                self.tweetsRepository
                    .nekogoToggleExecutedAt?
                    .onNext(index)
            
            default:
                //ローディングのせるの選択解除をするための処理
                return
            }
        }
        
        self.authExecutedAt = AnyObserver<String>() { [unowned self] authedAt in
            self.authRepository.getRequestToken()
        }
    }
}
