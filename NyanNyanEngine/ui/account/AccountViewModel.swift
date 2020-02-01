//
//  AccountViewModel.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 9/16/19.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation
import RxSwift

protocol AccountViewModelInput: AnyObject {
    //TODO: 後々、日付型っぽいやつにする
    var logoutExecutedAt: AnyObserver<String>? { get }
}

protocol AccountViewModelOutput: AnyObject {
    var currentAccount: Observable<Account> { get }
    var currentNyanNyanAccount: Observable<NyanNyanUser> { get }
    var isLoading: Observable<Bool> { get }
    var logoutSucceeded: Observable<Bool>? { get }
}

final class AccountViewModel: AccountViewModelInput, AccountViewModelOutput {
    private let authRepository: BaseAuthRepository
    private let tweetsRepository: BaseTweetsRepository
    private let loadingStatusRepository: LoadingStatusRepository
    private let disposeBag = DisposeBag()
    
    var logoutExecutedAt: AnyObserver<String>? = nil
    let currentAccount: Observable<Account>
    let currentNyanNyanAccount: Observable<NyanNyanUser>
    let isLoading: Observable<Bool>
    let logoutSucceeded: Observable<Bool>?
    
    init(authRepository: BaseAuthRepository = AuthRepository.shared,
         tweetsRepository: BaseTweetsRepository = TweetsRepository.shared,
         loadingStatusRepository: LoadingStatusRepository = LoadingStatusRepository.shared){
        self.authRepository = authRepository
        self.tweetsRepository = tweetsRepository
        self.loadingStatusRepository = loadingStatusRepository
        
        self.currentAccount = authRepository.currentAccount
        self.currentNyanNyanAccount = authRepository.currentNyanNyanAccount
        self.isLoading = loadingStatusRepository.isLoading
        self.logoutSucceeded = authRepository.logoutSucceeded
        
        self.logoutExecutedAt = AnyObserver<String>() { executedAt in
            self.loadingStatusRepository.loadingStatusChangedTo.onNext(true)
            self.authRepository.invalidateAccountInfo() {
                self.authRepository
                    .accountUpdatedAt?
                    .onNext("")
                
                self.tweetsRepository
                    .buttonRefreshExecutedAt?
                    .onNext() { self.loadingStatusRepository.loadingStatusChangedTo.onNext(false) }
            }
            .subscribe()
            .disposed(by: self.disposeBag)
        }
    }
}
