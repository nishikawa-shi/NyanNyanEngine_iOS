//
//  TweetSummaryCell.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/05/01.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import UIKit
import Nuke

class TweetSummaryCell: UITableViewCell {
    @IBOutlet private weak var userImage: UIImageView!
    @IBOutlet private weak var userName: UILabel!
    @IBOutlet private weak var userId: UILabel!
    @IBOutlet private weak var publishedAt: UILabel!
    @IBOutlet private weak var tweetBody: UILabel!
    
    func configure(nyanNyan: NyanNyan) {
        nyanNyan.profileUrl
            .flatMap({ URL(string: $0) })
            .map({ Nuke.loadImage(with: $0, into: userImage)
                return
            })
        userName.text = nyanNyan.userName
        userId.text = nyanNyan.userId
        publishedAt.text = nyanNyan.nyanedAt
        tweetBody.text = nyanNyan.isNekogo ? nyanNyan.nekogo : nyanNyan.ningengo
    }
}
