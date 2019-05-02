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
    var refreshExecutedAt: AnyObserver<String>? { get }
}

protocol HomeTimelineViewModelOutput: AnyObject {
    var statuses: Observable<[Status]?> { get }
}

final class HomeTimelineViewModel: HomeTimelineViewModelInput, HomeTimelineViewModelOutput {
    private let tweetsRepository: BaseTweetsRepository
    private let authRepository: BaseAuthRepository
    private let disposeBag = DisposeBag()
    
    var authExecutedAt: AnyObserver<String>? = nil
    var refreshExecutedAt: AnyObserver<String>? = nil
    let statuses: Observable<[Status]?>
    
    init(tweetsRepository: BaseTweetsRepository = TweetsRepository.shared,
         authRepository: BaseAuthRepository = AuthRepository.shared) {
        self.tweetsRepository = tweetsRepository
        self.authRepository = authRepository
        
        let _statuses = BehaviorSubject<[Status]?>(value: nil)
        self.statuses = _statuses.asObservable()
        
        self.refreshExecutedAt = AnyObserver<String>() { [unowned self] updatedAt in
            self.tweetsRepository
                .getHomeTimeLine()
                .bind(to: _statuses)
                .disposed(by: self.disposeBag)
            print(updatedAt.element)
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
