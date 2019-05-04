//
//  HomeTimelineViewModel.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/04/30.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

protocol HomeTimelineViewModelInput: AnyObject {
    //TODO: 後々、日付型っぽいやつにする
    var authExecutedAt: AnyObserver<String>? { get }
    var buttonRefreshExecutedAt: AnyObserver<String>? { get }
    var pullToRefreshExecutedAt: AnyObserver<UIRefreshControl>? { get }
}

protocol HomeTimelineViewModelOutput: AnyObject {
    var statuses: Observable<[Status]?> { get }
}

final class HomeTimelineViewModel: HomeTimelineViewModelInput, HomeTimelineViewModelOutput {
    private let tweetsRepository: BaseTweetsRepository
    private let authRepository: BaseAuthRepository
    private let disposeBag = DisposeBag()
    
    var authExecutedAt: AnyObserver<String>? = nil
    var buttonRefreshExecutedAt: AnyObserver<String>? = nil
    var pullToRefreshExecutedAt: AnyObserver<UIRefreshControl>? = nil
    let statuses: Observable<[Status]?>
    
    init(tweetsRepository: BaseTweetsRepository = TweetsRepository.shared,
         authRepository: BaseAuthRepository = AuthRepository.shared) {
        self.tweetsRepository = tweetsRepository
        self.authRepository = authRepository
        
        let _statuses = BehaviorRelay<[Status]?>(value: nil)
        self.statuses = _statuses.asObservable()
        
        self.buttonRefreshExecutedAt = AnyObserver<String>() { [unowned self] updatedAt in
            self.tweetsRepository
                .getHomeTimeLine(uiRefreshControl: nil)
                .bind(to: _statuses)
                .disposed(by: self.disposeBag)
            print(updatedAt.element)
        }

        self.pullToRefreshExecutedAt = AnyObserver<UIRefreshControl>() { [unowned self] uiRefreshControl in
            self.tweetsRepository
                .getHomeTimeLine(uiRefreshControl: uiRefreshControl.element)
                .map {
                    sleep(1)
                    uiRefreshControl.element?.endRefreshing()
                    return $0 ?? []
                }
                .bind(to: _statuses)
                .disposed(by: self.disposeBag)
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
