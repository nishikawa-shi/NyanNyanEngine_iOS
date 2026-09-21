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
    //idが文字列なのは、v2のツイートIDがsnowflake IDの文字列表現で、
    //Intへ収めると桁が落ちて別のツイートと同じidになりうるため
    let id: String
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
        return id
    }
}
