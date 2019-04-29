//
//  Status.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/04/29.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation

struct Status: Codable {
    let truncated: Bool
    let createdAt: String
    let favorited: Bool
    let idStr: String
    let entities: Entity
    let text: String
    let id: Int
    let retweetCount: Int
    let retweeted: Bool
    let source: String
    let user: User
}
