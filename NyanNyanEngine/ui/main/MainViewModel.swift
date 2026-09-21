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
    func refreshTimeline()
}

protocol MainViewModelOutput: AnyObject {
}

final class MainViewModel: MainViewModelInput, MainViewModelOutput {
    private let tweetsRepository: BaseTweetsRepository
    private let loadingStatusRepository: BaseLoadingStatusRepository
    
    init(tweetsRepository: BaseTweetsRepository = TweetsRepository.shared,
         loadingStatusRepository: BaseLoadingStatusRepository = LoadingStatusRepository.shared) {
        self.tweetsRepository = tweetsRepository
        self.loadingStatusRepository = loadingStatusRepository
    }

    func refreshTimeline() {
        self.loadingStatusRepository
            .loadingStatusChangedTo
            .onNext(true)

        //消灯の知らせを先に取り出してから渡すのは、渡す先のリポジトリが
        //シングルトンで、自分自身を掴んだまま応答を待ててしまうため
        let loadingStatusRepository = self.loadingStatusRepository
        self.tweetsRepository.refreshTimeline(scrollingToTop: true) {
            loadingStatusRepository.loadingStatusChangedTo.onNext(false)
        }
    }
}
