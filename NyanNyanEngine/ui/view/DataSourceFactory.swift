//
//  DataSourceFactory.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 6/16/19.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation
import RxDataSources
import Nuke

class DataSourceFactory {
    static let shared = DataSourceFactory()
    
    private init() { }
    
    func createTweetSummary() -> RxTableViewSectionedAnimatedDataSource<NyanNyanSection> {
        return RxTableViewSectionedAnimatedDataSource<NyanNyanSection>(
            configureCell: { dataS, tableView, indexPath, item in
                switch(indexPath.section) {
                case 0:
                    let cell = tableView.dequeueReusableCell(withIdentifier: "TweetSummaryCell", for: indexPath) as! TweetSummaryCell
                    
                    item.profileUrl
                        .flatMap({ URL(string: $0) })
                        .map({ Nuke.loadImage(with: $0, into: cell.userImage)
                            return
                        })
                    cell.userName?.text = item.userName
                    cell.userId?.text = item.userId
                    cell.publishedAt?.text = item.nyanedAt
                    cell.tweetBody?.text = item.isNekogo ? item.nekogo : item.ningengo
                    return cell
                    
                case 1:
                    return tableView.dequeueReusableCell(withIdentifier: "LoadingCell", for: indexPath) as! LoadingCell
                    
                default:
                    return UITableViewCell()
                }
        })
    }
}
