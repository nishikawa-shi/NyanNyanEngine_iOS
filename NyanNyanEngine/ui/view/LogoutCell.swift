//
//  LogoutCell.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 9/22/19.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import UIKit

class LogoutCell: UITableViewCell {
    
    func configure(account: Account?) {
        let account = account ?? Account()
        if account.isDefaultAccount() {
            //TODO: ログアウトボタンを無効化する処理
        }
    }
}
