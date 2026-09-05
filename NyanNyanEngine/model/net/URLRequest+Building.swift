//
//  URLRequest+Building.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2026/08/30.
//  Copyright © 2026 Tetsuya Nishikawa. All rights reserved.
//

import Foundation

//プロパティを直接書き換えず、設定済みの値を返す形にしているのは、
//呼び出し側が可変な束縛を持たずに組み立てられるようにするため
extension URLRequest {
    func adding(header value: String, forField field: String) -> URLRequest {
        var request = self
        request.addValue(value, forHTTPHeaderField: field)
        return request
    }

    func posting(body: Data) -> URLRequest {
        var request = self
        request.httpMethod = "POST"
        request.httpBody = body
        return request
    }
}
