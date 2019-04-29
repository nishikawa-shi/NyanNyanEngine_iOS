//
//  UserMention.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/04/29.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation

struct UserMention: Codable {
    let name: String
    let idStr: String
    let id: Int
    let indices: [Int]
    let screenName: String
}
