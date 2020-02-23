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
        
        if(isNekogo(sourceStr: sourceStr)) {
            return sourceStr
        }
        
        let nekogoSource = sourceStr.md5()
        let nekogoBody = String(nekogoSource.prefix(3))
            .reduce("") { $0 + getNekogoBody(sourceChar: $1) }
        let nyankoSuffix = String(nekogoSource.suffix(1))
            .reduce("") { $0 + getNekogoSuffix(sourceChar: $1) }
        return nekogoBody + nyankoSuffix
    }
    
    func isNekogo(sourceStr: String) -> Bool {
        let nekogoRange = [R.string.stringValues.nekosan_nakigoe_type1(),
                           R.string.stringValues.nekosan_nakigoe_type2(),
                           R.string.stringValues.nekosan_nakigoe_type3(),
                           R.string.stringValues.nekosan_nakigoe_type4(),
                           R.string.stringValues.nekosan_nakigoe_type5(),
                           R.string.stringValues.nekosan_nakigoe_type6(),
                           R.string.stringValues.nekosan_nakigoe_type7(),
                           R.string.stringValues.nekosan_nakigoe_type8(),
                           R.string.stringValues.nekosan_nakigoe_type9(),
            ].joined(separator: "|")
        let nekogoBodyPattern = ["(", nekogoRange, ")"].joined()
        
        let nekosanPrefixPattern = "(😊|🙁|🐤|🐟|🏆|🌈|🎊|:\\)|XD)"
        
        let nekogoHashTagRange = [R.string.stringValues.settings_title_hashtag_engine(),
                                  R.string.stringValues.settings_title_hashtag_nadenade()]
        let nekogoHashTagPattern = nekogoHashTagRange.map { _ in "(\\s?#.{1,15})?" }.joined()
        
        let pattern = ["^", nekogoBodyPattern, "{1,3}", nekosanPrefixPattern, "?", nekogoHashTagPattern, "$"].joined()
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        return (regex.matches(in: sourceStr,
                              range: NSRange(location: 0, length:sourceStr.count))
            .count) > 0
    }
    
    private func getNekogoBody(sourceChar: Character) -> String {
        switch(sourceChar) {
        case "0":
            return R.string.stringValues.nekosan_nakigoe_type1()
        case "1":
            return R.string.stringValues.nekosan_nakigoe_type1()
        case "2":
            return R.string.stringValues.nekosan_nakigoe_type2()
        case "3":
            return R.string.stringValues.nekosan_nakigoe_type2()
        case "4":
            return R.string.stringValues.nekosan_nakigoe_type3()
        case "5":
            return R.string.stringValues.nekosan_nakigoe_type3()
        case "6":
            return R.string.stringValues.nekosan_nakigoe_type4()
        case "7":
            return R.string.stringValues.nekosan_nakigoe_type4()
        case "8":
            return R.string.stringValues.nekosan_nakigoe_type4()
        case "9":
            return R.string.stringValues.nekosan_nakigoe_type5()
        case "a":
            return R.string.stringValues.nekosan_nakigoe_type5()
        case "b":
            return R.string.stringValues.nekosan_nakigoe_type6()
        case "c":
            return R.string.stringValues.nekosan_nakigoe_type7()
        case "d":
            return R.string.stringValues.nekosan_nakigoe_type8()
        case "e":
            return R.string.stringValues.nekosan_nakigoe_type9()
        case "f":
            return R.string.stringValues.nekosan_nakigoe_type9()
        default:
            return R.string.stringValues.nekosan_nakigoe_type99()
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
