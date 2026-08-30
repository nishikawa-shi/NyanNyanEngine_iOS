//
//  Account.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 9/23/19.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation

struct Account: Equatable {
    static func == (lhs: Account, rhs: Account) -> Bool {
        return lhs.headerName == rhs.headerName
            && lhs.user.name == rhs.user.name
            && lhs.user.username == rhs.user.username
            && lhs.user.profileImageUrl == rhs.user.profileImageUrl
    }
    
    let user: User
    let headerName: String
    //idが空文字なのは、にゃんにゃ先生がXのアカウントを持たないため。
    //先生を値の不在ではなく人格として型で表す件は Issue #146 で扱う
    init(user: User = User(id: "",
                           name: R.string.stringValues.default_user_name(),
                           username: R.string.stringValues.default_user_id(),
                           profileImageUrl: nil),
         headerName: String = R.string.stringValues.default_timeline_name()) {
        self.user = user
        self.headerName = headerName
    }
}

extension Account {
    func isDefaultAccount() -> Bool {
        return self == Account()
    }
}
