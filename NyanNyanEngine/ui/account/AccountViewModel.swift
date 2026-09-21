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
    func logout()
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
    }

    func logout() {
        self.loadingStatusRepository.loadingStatusChangedTo.onNext(true)

        //消灯の知らせを先に取り出してから渡すのは、取得が終わる前に画面を離れると
        //解放され、取りこぼすと共有のインジケータが回ったままになるため
        let loadingStatusRepository = self.loadingStatusRepository
        self.authRepository.invalidateAccountInfo() { [weak self] in
            guard let self = self else { return }
            self.authRepository.reloadAccount()

            self.tweetsRepository.refreshTimeline(scrollingToTop: true) {
                loadingStatusRepository.loadingStatusChangedTo.onNext(false)
            }
        }
        .subscribe()
        .disposed(by: self.disposeBag)
    }
}
