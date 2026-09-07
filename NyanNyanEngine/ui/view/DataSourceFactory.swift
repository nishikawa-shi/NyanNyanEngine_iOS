//
//  DataSourceFactory.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 6/16/19.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation
import UIKit
import RxDataSources

class DataSourceFactory {
    static let shared = DataSourceFactory()

    private init() { }

    func createTweetSummary() -> RxTableViewSectionedAnimatedDataSource<NyanNyanSection> {
        return RxTableViewSectionedAnimatedDataSource<NyanNyanSection>(
            configureCell: { dataS, tableView, indexPath, item in
                let cell = tableView.dequeueReusableCell(withIdentifier: "TweetSummaryCell", for: indexPath) as! TweetSummaryCell
                cell.configure(nyanNyan: item)
                return cell
        })
    }
}
