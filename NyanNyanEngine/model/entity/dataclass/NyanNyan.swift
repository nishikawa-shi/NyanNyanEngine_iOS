//
//  NyanNyan.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/05/06.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation
import Differentiator

struct NyanNyan: Equatable {
    let id: Int
    let profileUrl: String?
    let userName: String
    let userId: String
    let nyanedAt: String
    let nekogo: String
    let ningengo: String
    var isNekogo: Bool = true
}
extension NyanNyan: IdentifiableType {
    var identity: String {
        return [ningengo, userId].joined()
    }
}
