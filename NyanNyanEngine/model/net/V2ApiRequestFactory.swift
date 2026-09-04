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
    func createRevokeTokenRequest(token: String, tokenTypeHint: String, clientId: String) -> URLRequest?
}

//Authorizationヘッダを載せないのは、アクセストークンの鮮度管理を
//XAuthClientへ集約し、期限切れの判断がこのクラスへ漏れないようにするため
class V2ApiRequestFactory: BaseV2ApiRequestFactory {
    static let shared = V2ApiRequestFactory()
    private init() { }

    private let myAccountApiUrl = "https://api.x.com/2/users/me?user.fields=profile_image_url"
    private let postTweetApiUrl = "https://api.x.com/2/tweets"
    private let revokeTokenApiUrl = "https://api.x.com/2/oauth2/revoke"

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
            .posting(body: body)
            .adding(header: "application/json", forField: "Content-Type")
    }

    //失効させるトークンを引数で受け取るのは、どのトークンを持っているかを
    //知っているのが XAuthClient の側だけのため
    func createRevokeTokenRequest(token: String, tokenTypeHint: String, clientId: String) -> URLRequest? {
        guard let url = URL(string: revokeTokenApiUrl) else { return nil }
        let body = formUrlEncoded(parameters: [("token", token),
                                               ("token_type_hint", tokenTypeHint),
                                               ("client_id", clientId)])

        return URLRequest(url: url,
                          cachePolicy: .reloadIgnoringLocalCacheData,
                          timeoutInterval: 10)
            .posting(body: body)
            .adding(header: "application/x-www-form-urlencoded", forField: "Content-Type")
    }

    //URLComponentsのクエリ生成に任せないのは、フォーム本文では区切りの意味を持つ
    //「+」と「=」がクエリの文脈では素通しになり、トークンが壊れて届くため
    private func formUrlEncoded(parameters: [(String, String)]) -> Data {
        let unreserved = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        return Data(parameters
            .map { [$0.0, $0.1.addingPercentEncoding(withAllowedCharacters: unreserved) ?? ""].joined(separator: "=") }
            .joined(separator: "&")
            .utf8)
    }
}
