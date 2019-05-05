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
}

protocol HomeTimelineViewModelOutput: AnyObject {
    var statuses: Observable<[Status]?> { get }
    var currentUser: Observable<String> { get }
    var isLoading: Observable<Bool> { get }
}

final class HomeTimelineViewModel: HomeTimelineViewModelInput, HomeTimelineViewModelOutput {
    private let tweetsRepository: BaseTweetsRepository
    private let authRepository: BaseAuthRepository
    private let loadingStatusRepository: BaseLoadingStatusRepository
    private let disposeBag = DisposeBag()
    
    var authExecutedAt: AnyObserver<String>? = nil
    var buttonRefreshExecutedAt: AnyObserver<String>? = nil
    var pullToRefreshExecutedAt: AnyObserver<UIRefreshControl>? = nil
    let currentUser: Observable<String>
    let statuses: Observable<[Status]?>
    let isLoading: Observable<Bool>
    
    init(tweetsRepository: BaseTweetsRepository = TweetsRepository.shared,
         authRepository: BaseAuthRepository = AuthRepository.shared,
         loadingStatusRepository: BaseLoadingStatusRepository = LoadingStatusRepository.shared) {
        self.tweetsRepository = tweetsRepository
        self.authRepository = authRepository
        self.loadingStatusRepository = loadingStatusRepository
        
        self.currentUser = authRepository.currentUser
        self.statuses = tweetsRepository.statuses
        self.isLoading = loadingStatusRepository.isLoading
        
        self.buttonRefreshExecutedAt = AnyObserver<String>() { [unowned self] updatedAt in
            self.authRepository
                .loginExecutedAt?
                .onNext(updatedAt.element ?? "")
            
            self.tweetsRepository
                .buttonRefreshExecutedAt?
                .onNext() { self.loadingStatusRepository.loadingStatusChangedTo.onNext(false) }
            
            self.loadingStatusRepository
                .loadingStatusChangedTo
                .onNext(true)
        }
        
        self.pullToRefreshExecutedAt = AnyObserver<UIRefreshControl>() { [unowned self] uiRefreshControl in
            self.authRepository
                .loginExecutedAt?
                .onNext("")
            
            self.tweetsRepository
                .pullToRefreshExecutedAt?
                .onNext(uiRefreshControl.element)
            
            self.loadingStatusRepository
                .loadingStatusChangedTo
                .onNext(false)
        }
        
        self.authExecutedAt = AnyObserver<String>() { [unowned self] authedAt in
            self.authRepository
                .getRequestToken()
                .subscribe{
                    guard let url = $0.element else { return }
                    UIApplication.shared.open(url, options: [:], completionHandler: nil) }
                .disposed(by: self.disposeBag)
            print(authedAt.element)
        }
    }
}
