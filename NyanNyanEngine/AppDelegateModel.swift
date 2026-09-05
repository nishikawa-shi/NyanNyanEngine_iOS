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
    var authExecutedAt: AnyObserver<String>? { get }
    //受け取ったURLを扱えたかを呼び出し側へ返す必要があるため、
    //他の入力と違いAnyObserverではなくメソッドにしている
    func resumeAuthorization(with url: URL) -> Bool
}

protocol AppDelegateModelOutput: AnyObject {
    
}

final class AppDelegateModel: AppDelegateModelInput, AppDelegateModelOutput {
    private let authRepository: BaseAuthRepository
    
    var authExecutedAt: AnyObserver<String>? = nil
    
    init(authRepository: BaseAuthRepository = AuthRepository.shared) {
        self.authRepository = authRepository
        
        self.authExecutedAt = AnyObserver<String> { [unowned self] _ in
            self.authRepository.authAppUser()
        }
    }

    func resumeAuthorization(with url: URL) -> Bool {
        return self.authRepository.resumeAuthorization(with: url)
    }
    
}
