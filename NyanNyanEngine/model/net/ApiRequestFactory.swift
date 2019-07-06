//
//  RequestTokenUrlRequestFactory.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/05/02.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation
import CryptoSwift

protocol BaseApiRequestFactory: AnyObject {
    func createRequestTokenRequest() -> URLRequest?
    func createAccessTokenRequest(redirectedUrl: URL) -> URLRequest?
}

class ApiRequestFactory: BaseApiRequestFactory {
    private let apiSecret: String
    private let accessTokenSecret: String
    
    private let allowedCharacterSet: CharacterSet
    private var params: [(key: String, value: String)]
    
    private let requestTokenApiUrl = "https://api.twitter.com/oauth/request_token"
    private let accessTokenApiUrl = "https://api.twitter.com/oauth/access_token"
    private let homeTimelineApiUrl = "https://api.twitter.com/1.1/statuses/home_timeline.json"
    private let postTweetApiUrl = "https://api.twitter.com/1.1/statuses/update.json"
    
    #if DEBUG
    private let callBackUrl: String! = "https://nyannyanengine-ios-d.firebaseapp.com/authorized/"
    #elseif RELEASE
    private let callBackUrl: String! = "https://nyannyanengine.firebaseapp.com/authorized/"
    #else
    private let callBackUrl: String! = nil
    #endif
    
    
    init(apiKey: String = "abcdefghijklMNOPQRSTU0123",
         apiSecret: String = "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMN",
         oauthNonce: String = "0000",
         accessTokenSecret: String = "",
         accessToken: String = "") {
        self.apiSecret = apiSecret
        self.accessTokenSecret = accessTokenSecret
        
        var baseAllowed = CharacterSet.alphanumerics
        baseAllowed.insert(charactersIn: "-._~")
        self.allowedCharacterSet = baseAllowed
        
        self.params =  [(key: "oauth_consumer_key", value: apiKey),
                        (key: "oauth_nonce", value: oauthNonce),
                        (key: "oauth_signature_method", value: "HMAC-SHA1"),
                        (key: "oauth_timestamp", value: String(Int(NSDate().timeIntervalSince1970))),
                        (key: "oauth_token", value: accessToken),
                        (key: "oauth_version", value: "1.0")]
            .map { (key: $0.key, value: $0.value.addingPercentEncoding(withAllowedCharacters: baseAllowed)!) }
    }
    
    func createHomeTimelineRequest(maxId: String? = nil) -> URLRequest? {
        var query = ""
        if let maxId = maxId {
            params.append((key: "max_id", value: maxId))
            params.append((key: "count", value: "200"))
            query += ("?max_id=" + maxId + "&count=200")
        }
        let fullPath = homeTimelineApiUrl + query
        
        return createSignedUrlRequest(baseUrlStr: homeTimelineApiUrl,
                                      urlStr: fullPath,
                                      requestMethod: "GET")
    }
    
    func createRequestTokenRequest() -> URLRequest? {
        params.append((key: "oauth_callback", value: callBackUrl))
        return createSignedUrlRequest(baseUrlStr: requestTokenApiUrl,
                                      urlStr: requestTokenApiUrl,
                                      requestMethod: "POST")
    }
    
    func createAccessTokenRequest(redirectedUrl: URL) -> URLRequest? {
        guard let query = NSURLComponents(string: redirectedUrl.absoluteString)?.query else { return nil }
        let fullPath = accessTokenApiUrl + "?" + query
        
        return createSignedUrlRequest(baseUrlStr: accessTokenApiUrl,
                                      urlStr: fullPath,
                                      requestMethod: "POST")
    }
    
    func createPostTweetRequest(tweetBody: String) -> URLRequest? {
        params.append((key: "status", value: tweetBody))
        
        let query = "?status="
            + tweetBody.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!
        let fullPath = postTweetApiUrl + query
        
        return createSignedUrlRequest(baseUrlStr: postTweetApiUrl,
                                      urlStr: fullPath,
                                      requestMethod: "POST")
    }
    
    private func createSignedUrlRequest(baseUrlStr: String, urlStr: String, requestMethod: String) -> URLRequest? {
        params.append((key: "oauth_signature", value: createSignature(params: params, requestMethod: requestMethod, apiUrl: baseUrlStr)))
        
        guard let urlObj = URL(string: urlStr) else { return nil }
        var urlRequest = URLRequest(url: urlObj,
                                    cachePolicy: .reloadIgnoringLocalCacheData,
                                    timeoutInterval: 5)
        
        urlRequest.httpMethod = requestMethod
        urlRequest.addValue(createAuthorizationValue(params: params), forHTTPHeaderField: "Authorization")
        
        return urlRequest
    }
    
    private func createSignature(params: [(key: String, value: String)], requestMethod: String, apiUrl: String) -> String {
        let signatureKey = apiSecret.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!
            + "&"
            + accessTokenSecret.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!
        
        let signatureData = [requestMethod.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!,
                             apiUrl.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!,
                             createSignatureBody(params: params)]
            .joined(separator: "&")
        let sigKeyByte = signatureKey.data(using: .utf8)!.bytes
        let sigDataByte = signatureData.data(using: .utf8)!.bytes
        let hmac = try! HMAC(key: sigKeyByte, variant: .sha1).authenticate(sigDataByte)
        return Data(hmac).base64EncodedString()
    }
    
    private func createSignatureBody(params: [(key: String, value: String)]) -> String {
        return params.sorted{ $0.key < $1.key }
            .map { [$0.key.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!,
                    $0.value.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!]
                .joined(separator: "=") }
            .joined(separator: "&")
            .addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!
    }
    
    private func createAuthorizationValue(params: [(key: String, value: String)]) -> String {
        let body =  params
            .map { [$0.key.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!,
                    $0.value.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!]
                .joined(separator: "=") }
            .joined(separator: ",")
        return "OAuth " + body
    }
}
