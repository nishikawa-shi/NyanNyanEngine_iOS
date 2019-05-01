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
    var refreshExecutedAt: AnyObserver<String>? { get }
}

protocol HomeTimelineViewModelOutput: AnyObject {
    var statuses: Observable<[Status]?> { get }
}

final class HomeTimelineViewModel: HomeTimelineViewModelInput, HomeTimelineViewModelOutput {
    private let tweetsRepository: BaseTweetsRepository
    private let disposeBag = DisposeBag()
    
    var refreshExecutedAt: AnyObserver<String>? = nil
    let statuses: Observable<[Status]?>
    
    init(tweetsRepository: BaseTweetsRepository = TweetsRepository.shared) {
        self.tweetsRepository = tweetsRepository
        let _statuses = BehaviorSubject<[Status]?>(value: nil)
        self.statuses = _statuses.asObservable()
        
        self.refreshExecutedAt = AnyObserver<String>() { updatedAt in
            self.tweetsRepository
                .getHomeTimeLine()
                .bind(to: _statuses)
                .disposed(by: self.disposeBag)
            print(updatedAt.element)
        }
    }
}
