//
//  SwitchConfigCell.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2/23/20.
//  Copyright © 2020 Tetsuya Nishikawa. All rights reserved.
//

import UIKit

class SwitchConfigCell: UITableViewCell {
    enum SwitchConfigCellType {
        case hashtagEngine
        case hashtagNadenade
    }
    
    @IBOutlet weak var configName: UILabel!
    @IBOutlet weak var configValue: UISwitch!
    
    private var _hashTagType: LocalSettingsRepository.HashTagTypes? = nil
    var hashTagType: LocalSettingsRepository.HashTagTypes? { return self._hashTagType }
    
    func configure(type: SwitchConfigCellType) {
        switch type {
        case .hashtagEngine:
            self.configName.text = R.string.stringValues.settings_title_hashtag_engine()
            self._hashTagType = .hashTagEngine
            self.configValue.isOn = LocalSettingsRepository.shared.getHashTagSetting(type: .hashTagEngine).isEnabled
            break
        case .hashtagNadenade:
            self.configName.text = R.string.stringValues.settings_title_hashtag_nadenade()
            self._hashTagType = .hashTagNadeNade
            self.configValue.isOn = LocalSettingsRepository.shared.getHashTagSetting(type: .hashTagNadeNade).isEnabled
            break
        }
    }
}
