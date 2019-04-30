//
//  HomeTimelineViewModel.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/04/30.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

protocol HomeTimelineViewModelInput: AnyObject {
    //TODO: 後々、日付型っぽいやつにする
    var refreshExecutedAt: AnyObserver<String> { get }
}

protocol HomeTimelineViewModelOutput: AnyObject {
    var statuses: Observable<[Status]?> { get }
}

final class HomeTimelineViewModel: HomeTimelineViewModelInput, HomeTimelineViewModelOutput {
    let refreshExecutedAt: AnyObserver<String>
    let statuses: Observable<[Status]?>
    
    init() {
        let _refreshExecutedAt = PublishRelay<String>()
        self.refreshExecutedAt = AnyObserver<String>() { event in
            guard let text = event.element else { return }
            _refreshExecutedAt.accept(text)
        }
        
        let _statuses = BehaviorRelay<[Status]?>(value: nil)
        self.statuses = _statuses.asObservable()
    }
}
