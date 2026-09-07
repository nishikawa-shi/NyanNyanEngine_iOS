//
//  NyanNyanSection.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 6/16/19.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation
import RxDataSources

struct NyanNyanSection {
    var items: [Item]
}
extension NyanNyanSection: SectionModelType {
    typealias Item = NyanNyan

    init(original: NyanNyanSection, items: [NyanNyan]) {
        self = original
        self.items = items
    }
}
extension NyanNyanSection: AnimatableSectionModelType {
    //値を持たせていないのは、一覧のセクションが1つしかなく、
    //区別する相手が居ないため
    var identity: String {
        return "NyanNyan"
    }
    typealias Identity = String
}
