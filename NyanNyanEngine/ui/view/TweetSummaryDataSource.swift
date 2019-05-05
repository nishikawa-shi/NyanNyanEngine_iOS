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
    typealias Element = [Status]
    
    var _itemModels: [Status] = []
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _itemModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TweetSummaryCell", for: indexPath) as? TweetSummaryCell else {
            return UITableViewCell()
        }
        
        let tekitouUrlStr = "https://pbs.twimg.com/profile_images/1003237257631821824/EN5tK3hB_normal.jpg"
        guard let url = URL(string: tekitouUrlStr) else { return UITableViewCell() }
        Nuke.loadImage(with: url, into: cell.userImage)
        
        let element = _itemModels[indexPath.row]
        cell.userName?.text = element.user.name
        cell.userId?.text = element.user.screenName
        cell.tweetBody?.text = element.text
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
