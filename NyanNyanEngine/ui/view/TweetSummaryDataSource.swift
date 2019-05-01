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
        let element = _itemModels[indexPath.row]
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