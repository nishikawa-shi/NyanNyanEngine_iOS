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
    var loadingStatusChangedTo: AnyObserver<Bool> { get }
}

class LoadingStatusRepository: BaseLoadingStatusRepository {
    static let shared = LoadingStatusRepository()
    
    let isLoading: Observable<Bool>
    let loadingStatusChangedTo: AnyObserver<Bool>
    
    private init() {
        let _isLoading = BehaviorRelay<Bool>(value: false)
        self.isLoading = _isLoading.asObservable()
        
        self.loadingStatusChangedTo = AnyObserver<Bool> { newStatus in
            _isLoading.accept(newStatus.element ?? false)
            Observable<Bool>
                .create { _ in Disposables.create()}
                .bind(to: _isLoading)
                .dispose()
        }
    }
}
