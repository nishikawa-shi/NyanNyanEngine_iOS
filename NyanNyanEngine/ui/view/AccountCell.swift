//
//  AccountCell.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 9/23/19.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import UIKit

class AccountCell: UITableViewCell {
    @IBOutlet private weak var userImage: UIImageView!
    @IBOutlet private weak var userName: UILabel!
    @IBOutlet private weak var userId: UILabel!
    
    func configure(account: Account?) {
        let user = account?.user ?? Account().user
        userImage.setNekosanImage(urlString: user.getFineImageUrl())
        userName.text = user.name
        userId.text = "@" + user.screenName
    }
}
