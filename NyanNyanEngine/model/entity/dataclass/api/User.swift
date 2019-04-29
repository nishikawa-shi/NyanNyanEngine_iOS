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
    let profileSidebarFillColor: String
    let profileBackgroundTile: Bool
    let profileSidebarBorderColor: String
    let profileImageUrl: String
    let createdAt: String
    let location: String
    let followRequestSent: Bool
    let idStr: String
    let isTranslator: Bool
    let profileLinkColor: String
    let defaultProfile: Bool
    let url: String
    let contributorsEnabled: Bool
    let favouritesCount: Int
    let utcOffset: Int?
    let profileImageUrlHttps: String
    let id: Int
    let listedCount: Int
    let profileUseBackgroundImage: Bool
    let profileTextColor: String
    let followersCount: Int
    let lang: String
    let protected: Bool
    let geoEnabled: Bool
    let notifications: Bool
    let description: String
    let profileBackgroundColor: String
    let verified: Bool
    let timeZone: String?
    let profileBackgroundImageUrlHttps: String
    let statusesCount: Int
    let profileBackgroundImageUrl: String
    let defaultProfileImage: Bool
    let friendsCount: Int
    let following: Bool
    let showAllInlineMedia: Bool
    let screenName: String
}
