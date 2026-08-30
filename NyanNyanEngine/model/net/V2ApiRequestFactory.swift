//
//  V2ApiRequestFactory.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2026/08/30.
//  Copyright © 2026 Tetsuya Nishikawa. All rights reserved.
//

import Foundation

protocol BaseV2ApiRequestFactory: AnyObject {
    func createMyAccountRequest() -> URLRequest?
    func createPostTweetRequest(tweetBody: String) -> URLRequest?
}

//Authorizationヘッダを載せないのは、アクセストークンの鮮度管理を
//XAuthServiceへ集約し、期限切れの判断がこのクラスへ漏れないようにするため
class V2ApiRequestFactory: BaseV2ApiRequestFactory {
    private let myAccountApiUrl = "https://api.x.com/2/users/me?user.fields=profile_image_url"
    private let postTweetApiUrl = "https://api.x.com/2/tweets"

    func createMyAccountRequest() -> URLRequest? {
        guard let url = URL(string: myAccountApiUrl) else { return nil }
        return URLRequest(url: url,
                          cachePolicy: .reloadIgnoringLocalCacheData,
                          timeoutInterval: 10)
    }

    func createPostTweetRequest(tweetBody: String) -> URLRequest? {
        guard let url = URL(string: postTweetApiUrl),
            let body = try? JSONEncoder().encode(["text": tweetBody]) else { return nil }

        return URLRequest(url: url,
                          cachePolicy: .reloadIgnoringLocalCacheData,
                          timeoutInterval: 10)
            .posting(jsonBody: body)
            .adding(header: "application/json", forField: "Content-Type")
    }
}
