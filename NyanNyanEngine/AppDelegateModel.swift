//
//  AppDelegateModel.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/05/03.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation

protocol AppDelegateModelInput: AnyObject {
    func authenticateAppUser()
    func resumeAuthorization(with url: URL) -> Bool
}

protocol AppDelegateModelOutput: AnyObject {
    
}

final class AppDelegateModel: AppDelegateModelInput, AppDelegateModelOutput {
    private let authRepository: BaseAuthRepository
    
    init(authRepository: BaseAuthRepository = AuthRepository.shared) {
        self.authRepository = authRepository
    }

    func authenticateAppUser() {
        self.authRepository.authAppUser()
    }

    func resumeAuthorization(with url: URL) -> Bool {
        return self.authRepository.resumeAuthorization(with: url)
    }
    
}
