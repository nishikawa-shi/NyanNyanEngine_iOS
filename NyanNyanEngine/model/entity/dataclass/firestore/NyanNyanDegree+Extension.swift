//
//  NyanNyanDegree+Extension.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2/2/20.
//  Copyright © 2020 Tetsuya Nishikawa. All rights reserved.
//

import Foundation

extension Dictionary where Key == String, Value == Any {
    func toNyanNyanDegrees() -> [NyanNyanDegree] {
        return self.map { return Int($0.key) ?? 0}
            .sorted{ $0 > $1}
            .map {
                NyanNyanDegree(firestoreDegreeRecord: (self[String($0)] as? [String: Any]))
        }
    }
}
