//
//  V2TimelineResponse.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2026/09/21.
//  Copyright © 2026 Tetsuya Nishikawa. All rights reserved.
//

import Foundation

//ツイートと投稿者を別の場所へ分けて返すのがv2の形のため、投稿者を
//引き当てる手がかりは authorId だけになる。v1.1のように1件の中へ
//ユーザーが入ってこない
struct V2TimelineResponse: Codable {
    struct V2Post: Codable {
        let id: String
        let text: String
        //要求した属性までオプショナルにしているのは、v2が値を持たない属性を
        //応答へ書かない規約のため。1つ欠けただけでデコードは丸ごと失敗し、
        //読めたはずのツイートまで巻き添えで消える
        let createdAt: String?
        let authorId: String?
    }

    struct V2Includes: Codable {
        let users: [User]?
    }

    //dataが無いことを異常としていないのは、フォロー先に新しい投稿が
    //1つも無いとき、Xがdataそのものを書かずに返すため
    let data: [V2Post]?
    let includes: V2Includes?
}
