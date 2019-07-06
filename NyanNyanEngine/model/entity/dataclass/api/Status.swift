//
//  Status.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/04/29.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation

struct Status: Codable {
    let id: Int
    let text: String
    let createdAt: String
    let user: User
}
