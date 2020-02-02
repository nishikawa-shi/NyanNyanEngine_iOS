//
//  NyanNyanDegree.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2/2/20.
//  Copyright © 2020 Tetsuya Nishikawa. All rights reserved.
//

import Foundation

struct NyanNyanDegree {
    let name: String
    let point: Int
    
    init(firestoreDegreeRecord: [String: Any]? = nil) {
        self.name = (firestoreDegreeRecord?["nam"] as? String) ?? "tora"
        self.point = (firestoreDegreeRecord?["pt"] as? Int) ?? 999999
    }
}
