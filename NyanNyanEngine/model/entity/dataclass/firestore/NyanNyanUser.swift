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
    let rankName: String
    let nextRankPoint: Int?
    
    private let getRankLogic: (Int, [NyanNyanDegree]) -> String = { nyanNyanPoint, degreesMaster in
        let ranks = degreesMaster.sorted { $0.point > $1.point }
        for rank in ranks {
            if (nyanNyanPoint >= rank.point) {
                return rank.name
            }
        }
        return R.string.stringValues.settings_lowest_rank()
    }
    
    private let getNextLogic: (Int, [NyanNyanDegree]) -> Int? = { nyanNyanPoint, degreesMaster in
        let ranks = degreesMaster.sorted { $0.point < $1.point }
        for rank in ranks {
            if (nyanNyanPoint < rank.point) {
                return rank.point - nyanNyanPoint
            }
        }
        return nil
    }
    
    init(firestoreUserRecord: [String: Any]? = nil,
         firestoreDegreeRecords: [String: Any]? = nil) {
        self.nyanNyanPoint = (firestoreUserRecord?["np"] as? Int) ?? 0
        self.tweetCount = (firestoreUserRecord?["tc"] as? Int) ?? 0
        self.rankName = self.getRankLogic(self.nyanNyanPoint, firestoreDegreeRecords?.toNyanNyanDegrees() ?? [])
        self.nextRankPoint = self.getNextLogic(self.nyanNyanPoint, firestoreDegreeRecords?.toNyanNyanDegrees() ?? [])
    }
    
}
