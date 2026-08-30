//
//  V2TweetResponse.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2026/08/30.
//  Copyright © 2026 Tetsuya Nishikawa. All rights reserved.
//

import Foundation

//投稿者の情報を持たないのは、POST /2/tweets の応答が id と text しか
//返さないため。投稿後のねこさんポイント加算は本文だけで完結させる
struct V2TweetResponse: Codable {
    struct V2Tweet: Codable {
        let id: String
        let text: String
    }

    let data: V2Tweet
}
