//
//  TweetSummaryDataSource.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/05/01.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import Nuke

class TweetSummaryDataSource: NSObject, UITableViewDataSource {
    typealias Element = [NyanNyan]
    
    var _itemModels: [NyanNyan] = []
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _itemModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TweetSummaryCell", for: indexPath) as? TweetSummaryCell else {
            return UITableViewCell()
        }
        
        let element = _itemModels[indexPath.row]
        
        element.profileUrl
            .flatMap({ URL(string: $0) })
            .map({ Nuke.loadImage(with: $0, into: cell.userImage)
                return
            })
        
        cell.userName?.text = element.userName
        cell.userId?.text = element.userId
        cell.publishedAt?.text = element.nyanedAt
        cell.tweetBody?.text = element.isNekogo ? element.nekogo : element.ningengo
        return cell
    }
}

extension TweetSummaryDataSource: RxTableViewDataSourceType {
    
    func tableView(_ tableView: UITableView, observedEvent: Event<Element>) {
        Binder(self) { datasource, element in
            datasource._itemModels = element
            tableView.reloadData()
            }.on(observedEvent)
    }
}
