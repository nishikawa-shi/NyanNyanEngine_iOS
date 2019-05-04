//
//  AppDelegateModel.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/05/03.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation
import RxSwift

protocol AppDelegateModelInput: AnyObject {
    var loginExecutedAt: AnyObserver<URL>? { get }
}

protocol AppDelegateModelOutput: AnyObject {
    
}

final class AppDelegateModel: AppDelegateModelInput, AppDelegateModelOutput {
    private let authRepository: BaseAuthRepository
    private let tweetsRepository: BaseTweetsRepository

    private let disposeBag = DisposeBag()
    
    var loginExecutedAt: AnyObserver<URL>? = nil

    init(authRepository: BaseAuthRepository = AuthRepository.shared,
         tweetsRepository: BaseTweetsRepository = TweetsRepository.shared) {
        self.authRepository = authRepository
        self.tweetsRepository = tweetsRepository
        
        self.loginExecutedAt = AnyObserver<URL>() { [unowned self] redirectedUrl in
            guard let url = redirectedUrl.element else { return }
            self.authRepository
                .downloadAccessToken(redirectedUrl: url) {
                    self.tweetsRepository
                        .buttonRefreshExecutedAt?
                        .onNext("")
                }
                .subscribe()
                .disposed(by: self.disposeBag)
        }
    }

}
