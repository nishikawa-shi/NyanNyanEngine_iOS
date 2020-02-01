//
//  AccountAttributeCell.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2/1/20.
//  Copyright © 2020 Tetsuya Nishikawa. All rights reserved.
//

import UIKit

class AccountAttributeCell: UITableViewCell {
    enum AccountAttrributeCellType {
        case nekosanPoint
    }

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    
    func configure(type: AccountAttrributeCellType,
                   nyanNyanUser: NyanNyanUser?) {
        self.titleLabel.text = R.string.stringValues.settings_title_nekosan_point()
        if let nyanNyanPoint = nyanNyanUser?.nyanNyanPoint {
            self.valueLabel.text = String(nyanNyanPoint)
        }
    }
}
