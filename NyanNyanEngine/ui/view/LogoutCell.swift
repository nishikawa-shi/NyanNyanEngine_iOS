//
//  LogoutCell.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 9/22/19.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import UIKit

class LogoutCell: UITableViewCell {
    
    @IBOutlet weak var logoutLabel: UILabel!
    
    func configure(account: Account?) {
        let account = account ?? Account()
        selectionStyle = account.isDefaultAccount() ? .none : .default
        logoutLabel.textColor = account.isDefaultAccount() ? UIColor(red: 0.51171875, green: 0.578125, blue: 0.5859375, alpha: 1) : UIColor(red: 220 / 256, green: 50 / 256, blue: 47 / 256, alpha: 1)
    }
}
