//
//  LoadingStatusRepository.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/05/05.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

protocol BaseLoadingStatusRepository {
    var isLoading: Observable<Bool> { get }
    var isInfiniteLoading: Observable<Bool> { get }
    var loadingStatusChangedTo: AnyObserver<Bool> { get }
    var infiniteLoadingStatusChangedTo: AnyObserver<Bool> { get }
}

class LoadingStatusRepository: BaseLoadingStatusRepository {
    static let shared = LoadingStatusRepository()
    
    let isLoading: Observable<Bool>
    let isInfiniteLoading: Observable<Bool>
    let loadingStatusChangedTo: AnyObserver<Bool>
    let infiniteLoadingStatusChangedTo: AnyObserver<Bool>
    
    private init() {
        let _isLoading = BehaviorRelay<Bool>(value: false)
        self.isLoading = _isLoading.asObservable()
        
        let _isInfiniteLoading = BehaviorRelay<Bool>(value: false)
        self.isInfiniteLoading = _isInfiniteLoading.asObservable()
        
        self.loadingStatusChangedTo = AnyObserver<Bool> { newStatus in
            _isLoading.accept(newStatus.element ?? false)
        }
        
        self.infiniteLoadingStatusChangedTo = AnyObserver<Bool> { newStatus in
            _isInfiniteLoading.accept(newStatus.element ?? false)
        }
    }
}
