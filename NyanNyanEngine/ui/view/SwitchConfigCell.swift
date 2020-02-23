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
    
    func configure(type: SwitchConfigCellType) {
        switch type {
            case .hashtagEngine:
                self.configName.text = R.string.stringValues.settings_title_hashtag_engine()
                break
            case .hashtagNadenade:
                self.configName.text = R.string.stringValues.settings_title_hashtag_nadenade()
                break
        }
    }
}
