//
//  NekosanRank.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2/2/20.
//  Copyright © 2020 Tetsuya Nishikawa. All rights reserved.
//

import Foundation

class NekosanRank {
    static func getNekosanPoint(nekogoStr: String) -> Int {
        if nekogoStr.contains("🌈") {
            return 80
        }
        if nekogoStr.contains("🐟") {
            return 80
        }
        if nekogoStr.contains("😊") {
            return 80
        }
        if nekogoStr.contains("🏆") {
            return 50
        }
        if nekogoStr.contains("🎊") {
            return 50
        }
        if nekogoStr.contains(":)") {
            return 30
        }
        if nekogoStr.contains("XD") {
            return 30
        }
        if nekogoStr.contains("🐤") {
            return 20
        }
        if nekogoStr.contains("🙁") {
            return 20
        }
        return 10
    }
}
