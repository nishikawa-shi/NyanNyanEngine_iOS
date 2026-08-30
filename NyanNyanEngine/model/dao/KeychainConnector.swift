//
//  KeychainConnector.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2026/08/30.
//  Copyright © 2026 Tetsuya Nishikawa. All rights reserved.
//

import Foundation
import Security

protocol BaseKeychainConnector: AnyObject {
    func registerData(key: String, value: Data) -> Bool
    func getData(withKey: String) -> Data?
    func deleteRecord(forKey: String) -> Void
}

class KeychainConnector: BaseKeychainConnector {
    static let shared = KeychainConnector()

    private let service: String

    //UserDefaultsConnectorと違いprivate initにしていないのは、
    //テストが実アカウントの認証情報を壊さないようserviceを差し替える必要があるため
    init(service: String = Bundle.main.bundleIdentifier ?? "com.ntetz.ios.NyanNyanEngine") {
        self.service = service
    }

    //@discardableResultを付けないのは、保存できたかを返す目的が
    //失敗を握りつぶさないことにあり、無視を許すと目的を損なうため
    func registerData(key: String, value: Data) -> Bool {
        //SecItemUpdateを使わないのは、未登録のキーへの更新が失敗し、
        //存在確認と更新で2回問い合わせる分岐が要るため
        deleteRecord(forKey: key)

        //WhenUnlockedだと画面ロック中のトークン更新ができず、
        //ThisDeviceOnlyを外すとバックアップ経由で別端末へ複製されうる
        let query = makeQuery(key: key,
                              adding: [kSecValueData as String: value,
                                       kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly])
        return SecItemAdd(query, nil) == errSecSuccess
    }

    func getData(withKey key: String) -> Data? {
        let query = makeQuery(key: key,
                              adding: [kSecReturnData as String: true,
                                       kSecMatchLimit as String: kSecMatchLimitOne])

        //SecItemCopyMatchingが結果をポインタ渡しで返すため、letでは受けられない
        var item: CFTypeRef?
        guard SecItemCopyMatching(query, &item) == errSecSuccess else { return nil }
        return item as? Data
    }

    func deleteRecord(forKey key: String) {
        SecItemDelete(makeQuery(key: key))
    }

    private func makeQuery(key: String, adding extra: [String: Any] = [:]) -> CFDictionary {
        let base: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                   kSecAttrService as String: service,
                                   kSecAttrAccount as String: key]
        return base.merging(extra) { _, added in added } as CFDictionary
    }
}
