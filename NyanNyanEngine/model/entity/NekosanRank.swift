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
        return getNekosanPrefixPoint(nekogoStr: nekogoStr) + getHashTagPoint()
    }
    
    static func getNekosanPrefixPoint(nekogoStr: String) -> Int {
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
    
    static func getHashTagPoint() -> Int {
        return LocalSettingsRepository.HashTagTypes.allCases.reduce(0) {
            return $0 + (LocalSettingsRepository.shared.getHashTagSetting(type: $1).isEnabled ? $1.getTweetPoint() : 0)
        }
    }
}
