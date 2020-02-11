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
        case nekosanRank
        case nekosanNext
    }

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    
    func configure(type: AccountAttrributeCellType,
                   nyanNyanUser: NyanNyanUser?) {
        switch type {
        case .nekosanPoint:
            self.titleLabel.text = R.string.stringValues.settings_title_nekosan_point()
            if let nyanNyanPoint = nyanNyanUser?.nyanNyanPoint {
                self.valueLabel.text = String(nyanNyanPoint)
            }
            break
        case .nekosanRank:
            self.titleLabel.text = "ネコさんランク"
            self.valueLabel.text =  nyanNyanUser?.rankName
            break
        case .nekosanNext:
            self.titleLabel.text = "次のランクまで"
            guard let nextRankPoint = nyanNyanUser?.nextRankPoint else {
                self.valueLabel.text = "-"
                break
            }
            self.valueLabel.text = String(nextRankPoint)
            break
        default:
            break
        }
    }
}
