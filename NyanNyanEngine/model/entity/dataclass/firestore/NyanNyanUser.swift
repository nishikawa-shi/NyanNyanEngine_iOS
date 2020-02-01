//
//  NyanNyanUser.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2/1/20.
//  Copyright © 2020 Tetsuya Nishikawa. All rights reserved.
//

import Foundation

struct NyanNyanUser {
    let nyanNyanPoint: Int
    let tweetCount: Int
    
    init(firestoreUserRecord: [String: Any]? = nil) {
        self.nyanNyanPoint = (firestoreUserRecord?["np"] as? Int) ?? 0
        self.tweetCount = (firestoreUserRecord?["tc"] as? Int) ?? 0
    }
}
