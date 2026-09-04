//
//  PlistConnector.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/05/02.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation

protocol BasePlistConnector: AnyObject {
    func getClientId() -> String?
    func getString(withKey: String) -> String?
}

class PlistConnector: BasePlistConnector {
    static let shared = PlistConnector()
    private init() { }
    
    private let keyFilePath = Bundle.main.path(forResource: "ApiKeys", ofType: "plist")
    
    func getApiKey() -> String? {
        #if DEBUG
        let keyName = "apiKeyD"
        #elseif RELEASE
        let keyName = "apiKey"
        #else
        return nil
        #endif
        return self.getString(withKey: keyName)
    }
    
    func getApiSecret() -> String? {
        #if DEBUG
        let keyName = "apiSecretD"
        #elseif RELEASE
        let keyName = "apiSecret"
        #else
        return nil
        #endif
        return self.getString(withKey: keyName)
    }
    
    //getApiKeyと違い環境で出し分けないのは、X側のアプリが1つしかなく
    //dev/prdで同じclient_idを共有しているため
    func getClientId() -> String? {
        return self.getString(withKey: "clientId")
    }

    func getString(withKey: String) -> String? {
        guard let keys = getKeys() else { return nil }
        return keys[withKey] as? String
    }
    
    private func getKeys() -> NSDictionary? {
        guard let keyFilePath = self.keyFilePath else { return nil }
        return NSDictionary(contentsOfFile: keyFilePath)
    }
}
