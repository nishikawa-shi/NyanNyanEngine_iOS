//
//  DefaultNekosanStatus.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/05/05.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

struct DefaultNekosan {
    let nyanNyanStatuses: [NyanNyan] = [
        NyanNyan(profileUrl: "https://nyannyanengine.firebaseapp.com/assets/nyannya_sensei.png",
                 userName: R.string.stringValues.default_user_name(),
                 userId: R.string.stringValues.default_user_id(),
                 nyanedAt: R.string.stringValues.default_user_posted_at(),
                 nekogo: R.string.stringValues.default_user_text(),
                 ningengo: R.string.stringValues.default_user_nekogo(),
                 isNekogo: false)
    ]
}
