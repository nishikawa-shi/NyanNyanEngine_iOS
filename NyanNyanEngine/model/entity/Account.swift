//
//  Account.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 9/23/19.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation

struct Account {
    let user: User
    let headerName: String
    init(user: User = User(name: R.string.stringValues.default_user_name(),
                           screenName: R.string.stringValues.default_user_id(),
                           profileImageUrlHttps: R.string.stringValues.default_user_profile_url()),
         headerName: String = R.string.stringValues.default_timeline_name()) {
        self.user = user
        self.headerName = headerName
    }
}
