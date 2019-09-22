//
//  SettingsSectionHeader.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 9/22/19.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import UIKit

class SettingsSectionHeader: UITableViewCell {
    //別にUITableViewCellである必要はなかったのだが、safe areaをうまく消す方法がUIViewで見つからなかったので、こうなっている。
    
    @IBOutlet private weak var headerTitle: UILabel!
    
    func configure(title: String) {
        headerTitle.text = title
    }
}
