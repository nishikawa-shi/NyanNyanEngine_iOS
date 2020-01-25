//
//  User.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/04/29.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation

struct User: Codable {
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
