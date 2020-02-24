//
//  LocalSettinngsRepository.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2/23/20.
//  Copyright © 2020 Tetsuya Nishikawa. All rights reserved.
//

import Foundation

class LocalSettingsRepository {
    enum HashTagTypes: String, CaseIterable {
        case hashTagEngine = "HashTagEngine"
        case hashTagNadeNade = "HashTagNadeNade"
        
        func getDefaultAvailavility() -> Bool {
            switch self {
            case .hashTagEngine:
                return true
            case .hashTagNadeNade:
                return false
            }
        }
        
        func getTweetText() -> String {
            switch self {
            case .hashTagEngine:
                return R.string.stringValues.settings_title_hashtag_engine()
            case .hashTagNadeNade:
                return R.string.stringValues.settings_title_hashtag_nadenade()
            }
        }
        
        func getTweetPoint() -> Int {
            switch self {
            case .hashTagEngine:
                return 30
            case .hashTagNadeNade:
                return 50
            }
        }
    }
    
    static let shared = LocalSettingsRepository()
    
    private let userDefaultsConnector: BaseUserDefaultsConnector
    
    private init(userDefaultsConnector: BaseUserDefaultsConnector = UserDefaultsConnector.shared) {
        self.userDefaultsConnector = userDefaultsConnector
    }
    
    func getHashTagSetting(type: HashTagTypes) -> HashTag {
        if self.userDefaultsConnector.getString(withKey: type.rawValue) == nil {
            self.userDefaultsConnector.registerString(key: type.rawValue,
                                                      value: String(type.getDefaultAvailavility()))
        }
        let boolVal = (self.userDefaultsConnector.getString(withKey: type.rawValue) as NSString?)?.boolValue ?? false
        return HashTag(name: type.rawValue, isEnabled: boolVal)
    }
    
    func saveHashtagSetting(type: HashTagTypes, value: Bool) {
        self.userDefaultsConnector.registerString(key: type.rawValue,
                                                  value: String(value))
    }
}
