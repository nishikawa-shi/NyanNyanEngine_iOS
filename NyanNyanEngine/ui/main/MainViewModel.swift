//
//  MainViewModel.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 10/8/19.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//


import Foundation
import RxSwift

protocol MainViewModelInput: AnyObject {
    //TODO: 後々、日付型っぽいやつにする
    var extraTimelineItemTap: AnyObserver<String>? { get }
}

protocol MainViewModelOutput: AnyObject {
}

final class MainViewModel: MainViewModelInput, MainViewModelOutput {
    private let tweetsRepository: BaseTweetsRepository
    private let loadingStatusRepository: BaseLoadingStatusRepository
    
    var extraTimelineItemTap: AnyObserver<String>? = nil
    
    init(tweetsRepository: BaseTweetsRepository = TweetsRepository.shared,
         loadingStatusRepository: BaseLoadingStatusRepository = LoadingStatusRepository.shared) {
        self.tweetsRepository = tweetsRepository
        self.loadingStatusRepository = loadingStatusRepository
        self.extraTimelineItemTap = AnyObserver<String>() { execetedAt in
            self.loadingStatusRepository
                .loadingStatusChangedTo
                .onNext(true)
            
            self.tweetsRepository
                .buttonRefreshExecutedAt?
                .onNext() { [unowned self] in
                    self.loadingStatusRepository.loadingStatusChangedTo.onNext(false)
            }
        }
    }
}
