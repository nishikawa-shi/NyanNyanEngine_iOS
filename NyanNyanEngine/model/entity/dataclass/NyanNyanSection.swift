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
    var idSuffix: String
}
extension NyanNyanSection: SectionModelType {
    typealias Item = NyanNyan
    
    init(original: NyanNyanSection, items: [NyanNyan]) {
        self = original
        self.items = items
    }
}
extension NyanNyanSection: AnimatableSectionModelType {
    var identity: String {
        return "NyanNyan" + idSuffix
    }
    typealias Identity = String
}
