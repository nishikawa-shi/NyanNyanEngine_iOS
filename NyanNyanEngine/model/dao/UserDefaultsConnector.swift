//
//  UserDefaultsConnector.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/05/03.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation

protocol BaseUserDefaultsConnector {
    func registerString(key: String, value: String)
    func getString(withKey: String) -> String?
    func isRegistered(withKey: String) -> Bool
    func deleteRecord(forKey: String) -> Void
}

class UserDefaultsConnector: BaseUserDefaultsConnector {
    static let shared = UserDefaultsConnector()
    private init() { }
    
    func isRegistered(withKey: String) -> Bool {
        return UserDefaults.standard.object(forKey: withKey) != nil
    }
    
    func getString(withKey: String) -> String? {
        return UserDefaults.standard.string(forKey: withKey)
    }
    
    func registerString(key: String, value: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    func deleteRecord(forKey key: String) {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
