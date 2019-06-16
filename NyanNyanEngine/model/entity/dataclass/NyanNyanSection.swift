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
