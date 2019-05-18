//
//  Nekosan.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/05/06.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation
import CryptoSwift

struct Nekosan {
    func createNekogo(sourceStr: String) -> String {
        if(sourceStr.isEmpty) {
            return ""
        }
        
        let nekogoSource = sourceStr.md5()
        let nekogoBody = String(nekogoSource.prefix(3))
            .reduce("") { $0 + getNekogoBody(sourceChar: $1) }
        let nyankoSuffix = String(nekogoSource.prefix(1))
            .reduce("") { $0 + getNekogoSuffix(sourceChar: $1) }
        return nekogoBody + nyankoSuffix
    }
    
    private func getNekogoBody(sourceChar: Character) -> String {
        switch(sourceChar) {
        case "0":
            return "にゃん"
        case "1":
            return "にゃん"
        case "2":
            return "にゃお"
        case "3":
            return "にゃお"
        case "4":
            return "にゃー"
        case "5":
            return "にゃー"
        case "6":
            return "にゃ"
        case "7":
            return "にゃ"
        case "8":
            return "にゃ"
        case "9":
            return "にゃーん"
        case "a":
            return "にゃーん"
        case "b":
            return "にゃーお"
        case "c":
            return "にゃおーん"
        case "d":
            return "にゃーおん"
        case "e":
            return "にゃあ"
        case "f":
            return "にゃあ"
        default:
            return "ごろごろ"
        }
    }
    
    private func getNekogoSuffix(sourceChar: Character) -> String {
        switch(sourceChar) {
        case "0":
            return ""
        case "1":
            return "😊"
        case "2":
            return "🙁"
        case "3":
            return ""
        case "4":
            return "🐤"
        case "5":
            return "🐳"
        case "6":
            return ""
        case "7":
            return "🐟"
        case "8":
            return "🐟"
        case "9":
            return "🏆"
        case "a":
            return ""
        case "b":
            return "🌈"
        case "c":
            return "🎊"
        case "d":
            return ""
        case "e":
            return ":)"
        case "f":
            return "XD"
        default:
            return "(^o^)"
        }
    }
}
