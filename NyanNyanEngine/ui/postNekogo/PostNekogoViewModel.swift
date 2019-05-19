//
//  PostNekogoViewModel.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/05/18.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

protocol PostNekogoViewModelInput: AnyObject {
    var originalTextChangedTo: AnyObserver<String?>? { get }
    var postExecutedAs: AnyObserver<String?>? { get }
}

protocol PostNekogoViewModelOutput: AnyObject {
    var nekogoText: Observable<String?> { get }
    var postSucceeded: Observable<Status?> { get }
    var isLoading: Observable<Bool> { get }
}

final class PostNekogoViewModel: PostNekogoViewModelInput, PostNekogoViewModelOutput {
    private let tweetsRepository: BaseTweetsRepository
    private let loadingStatusRepository: BaseLoadingStatusRepository
    private let disposeBag = DisposeBag()
    
    var originalTextChangedTo: AnyObserver<String?>? = nil
    var postExecutedAs: AnyObserver<String?>? = nil
    
    var nekogoText: Observable<String?>
    let postSucceeded: Observable<Status?>
    let isLoading: Observable<Bool>
    
    init(tweetsRepository: BaseTweetsRepository = TweetsRepository.shared,
         loadingStatusRepository: BaseLoadingStatusRepository = LoadingStatusRepository.shared) {
        self.tweetsRepository = tweetsRepository
        self.loadingStatusRepository = loadingStatusRepository
        
        let _nekogoText = BehaviorRelay<String?>(value: nil)
        self.nekogoText = _nekogoText.asObservable()
        self.postSucceeded = tweetsRepository.postedStatus
        self.isLoading = loadingStatusRepository.isLoading
        
        self.originalTextChangedTo = AnyObserver<String?> {
            guard let texiViewValue = $0.element,
                let originalText = texiViewValue else { return }
            _nekogoText.accept(Nekosan().createNekogo(sourceStr: originalText))
        }
        
        self.postExecutedAs = AnyObserver<String?> {
            guard let labelValue = $0.element else { return }
            self.loadingStatusRepository.loadingStatusChangedTo.onNext(true)
            tweetsRepository.postExecutedAs?.onNext(labelValue)
        }
        
        self.tweetsRepository.postedStatus.subscribe { _ in
            self.loadingStatusRepository
                .loadingStatusChangedTo
                .onNext(true)
            
            self.tweetsRepository
                .buttonRefreshExecutedAt?
                .onNext() { self.loadingStatusRepository.loadingStatusChangedTo.onNext(false) }
            }.disposed(by: self.disposeBag)
    }
}
