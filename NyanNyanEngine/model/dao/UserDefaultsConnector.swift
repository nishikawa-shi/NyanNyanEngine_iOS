//
//  UserDefaultsConnector.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/05/03.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation

protocol BaseUserDefaultsConnector {
    func isRegistered(withKey: String) -> Bool
}

class UserDefaultsConnector: BaseUserDefaultsConnector {
    static let shared = UserDefaultsConnector()
    private init() { }
    
    func isRegistered(withKey: String) -> Bool {
        return UserDefaults.standard.object(forKey: withKey) != nil
    }
}
