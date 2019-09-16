//
//  LoadingCell.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 6/30/19.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import UIKit

class LoadingCell: UITableViewCell {
    @IBOutlet private weak var infiniteLoadIndicator: UIActivityIndicatorView!
    
    func startAnimating() {
        infiniteLoadIndicator.startAnimating()
    }
}
