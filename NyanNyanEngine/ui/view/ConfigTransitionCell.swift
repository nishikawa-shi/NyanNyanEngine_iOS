//
//  ConfigTransitionCell.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2/23/20.
//  Copyright © 2020 Tetsuya Nishikawa. All rights reserved.
//

import UIKit

class ConfigTransitionCell: UITableViewCell {
    @IBOutlet weak var configNameLabel: UILabel!
    enum ConfigTransitionCellType {
        case hashTag
    }

    func configure(type: ConfigTransitionCellType) {
        switch type {
        case .hashTag:
            self.configNameLabel.text = R.string.stringValues.settings_title_hashtag()
            break
        }
    }
}
