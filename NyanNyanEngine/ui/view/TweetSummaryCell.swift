//
//  TweetSummaryCell.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/05/01.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import UIKit

class TweetSummaryCell: UITableViewCell {
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var userId: UILabel!
    @IBOutlet weak var publishedAt: UILabel!
    @IBOutlet weak var tweetBody: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        userImage.layer.cornerRadius = userImage.frame.size.width * 0.5
        userImage.clipsToBounds = true
    }
}
