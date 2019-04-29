//
//  Url.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/04/29.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation

struct Url: Codable {
    let expandedUrl: String
    let url: String
    let indices: [Int]
    let displayUrl: String
}
