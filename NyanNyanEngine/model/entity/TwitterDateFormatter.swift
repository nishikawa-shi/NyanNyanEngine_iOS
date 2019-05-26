//
//  DateFormatter.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/05/06.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation

class TwitterDateFormatter {
    func getNyanNyanTimeStamp(apiTimeStamp: String) -> String {
        let twitterDateFormatter = DateFormatter()
        twitterDateFormatter.dateFormat = "EEE MMM dd HH:mm:ss Z y"
        twitterDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard let createdAtDate = twitterDateFormatter.date(from: apiTimeStamp) else { return "秘密" }
        
        let createdAtUnixTimeStanp = createdAtDate.timeIntervalSince1970
        let currentUnixTimeStamp = Date().timeIntervalSince1970
        
        let passedSecFromCreatedAt = currentUnixTimeStamp - createdAtUnixTimeStanp
        
        if (passedSecFromCreatedAt < 60 * 60) {
            let passedMins = String(Int(passedSecFromCreatedAt / 60))
            let passedMinsSuffix = "分前"
            return [passedMins, passedMinsSuffix].joined()
        } else if (passedSecFromCreatedAt < 60 * 60 * 24) {
            let passedHours = String(Int(passedSecFromCreatedAt / (60 * 60)))
            let passedHoursSuffix = "時間前"
            return [passedHours + passedHoursSuffix].joined()
        } else if (passedSecFromCreatedAt < 60 * 60 * 24 * 30) {
            let passedDays = String(Int(passedSecFromCreatedAt / (60 * 60 * 24)))
            let passedDaysSuffix = "日前"
            return [passedDays, passedDaysSuffix].joined()
        } else {
            let farPassedDateFormatter = DateFormatter()
            farPassedDateFormatter.dateFormat = "y/MM"
            return farPassedDateFormatter.string(from: createdAtDate)
        }
    }
}
