//
//  Status.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/04/29.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation

struct Status: Codable {
    //Userを共有せず内側に持つのは、v1.1とv2でユーザーの表現が異なるため。
    //アプリ全体で使う型をv2に揃え、v1.1の形はタイムラインの移行時に
    //Statusごと消えるようここへ閉じ込めている
    struct TimelineUser: Codable {
        let name: String
        let screenName: String
        var profileImageUrlHttps: String? = nil

        func getFineImageUrl() -> String? {
            guard let normalSizeImageUrl = profileImageUrlHttps else { return nil }
            return normalSizeImageUrl.replacingOccurrences(
                of: "^https?://(.+)_normal(.+)$",
                with: "https://$1$2",
                options: .regularExpression,
                range: normalSizeImageUrl.range(of: normalSizeImageUrl))
        }
    }

    let id: Int
    let text: String
    let createdAt: String
    let user: TimelineUser
}
