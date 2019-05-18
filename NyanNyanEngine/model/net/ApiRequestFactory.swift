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
    private let apiKey: String
    private let apiSecret: String
    
    private let oauthNonce: String
    private let accessTokenSecret: String
    private let accessToken: String
    
    private let allowedCharacterSet: CharacterSet
    
    private let oauthTimeStamp = String(Int(NSDate().timeIntervalSince1970))
    private let oauthCallBackUrl = "https://nyannyanengine.firebaseapp.com/authorized/"
    private let oauthSignatureMethod = "HMAC-SHA1"
    private let oauthVersion = "1.0"
    
    private let requestTokenApiUrl = "https://api.twitter.com/oauth/request_token"
    private let accessTokenApiUrl = "https://api.twitter.com/oauth/access_token?"
    private let homeTimelineApiUrl = "https://api.twitter.com/1.1/statuses/home_timeline.json"
    private let postTweetApiUrl = "https://api.twitter.com/1.1/statuses/update.json"
    
    init(apiKey: String = "abcdefghijklMNOPQRSTU0123",
         apiSecret: String = "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMN",
         oauthNonce: String = "0000",
         accessTokenSecret: String = "",
         accessToken: String = "") {
        self.apiKey = apiKey
        self.apiSecret = apiSecret
        self.oauthNonce = oauthNonce
        self.accessTokenSecret = accessTokenSecret
        self.accessToken = accessToken
        
        var baseAllowed = CharacterSet.alphanumerics
        baseAllowed.insert(charactersIn: "-._~")
        self.allowedCharacterSet = baseAllowed
    }
    
    func createRequestTokenRequest() -> URLRequest? {
        guard let urlObj = URL(string: requestTokenApiUrl) else { return nil }
        var urlRequest = URLRequest(url: urlObj,
                                    cachePolicy: .reloadIgnoringLocalCacheData,
                                    timeoutInterval: 5)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue(makeAuthorizationValue(), forHTTPHeaderField: "Authorization")
        
        return urlRequest
    }
    
    func createAccessTokenRequest(redirectedUrl: URL) -> URLRequest? {
        guard let query = NSURLComponents(string: redirectedUrl.absoluteString)?.query,
            let urlObj = URL(string: accessTokenApiUrl + query) else { return nil }
        
        var urlRequest = URLRequest(url: urlObj,
                                    cachePolicy: .reloadIgnoringLocalCacheData,
                                    timeoutInterval: 5)
        
        urlRequest.httpMethod = "POST"
        return urlRequest
    }
    
    func createHomeTimelineRequest() -> URLRequest? {
        var params = [(key: "oauth_consumer_key", value: apiKey),
                      (key: "oauth_nonce", value: oauthNonce),
                      (key: "oauth_signature_method", value: oauthSignatureMethod),
                      (key: "oauth_timestamp", value: oauthTimeStamp),
                      (key: "oauth_token", value: accessToken),
                      (key: "oauth_version", value: oauthVersion)]
            .map { (key: $0.key, value: $0.value.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!) }
        params.append((key: "oauth_signature", value: createSignature(params: params, requestMethod: "GET", apiUrl: homeTimelineApiUrl)))
        
        let headerParams = params
            .map { [$0.key.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!,
                    $0.value.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!]
                .joined(separator: "=") }
            .joined(separator: ",")
        let headerValue = "OAuth " + headerParams
        
        guard let urlObj = URL(string: homeTimelineApiUrl) else { return nil }
        var urlRequest = URLRequest(url: urlObj,
                                    cachePolicy: .reloadIgnoringLocalCacheData,
                                    timeoutInterval: 5)
        urlRequest.httpMethod = "GET"
        urlRequest.addValue(headerValue, forHTTPHeaderField: "Authorization")
        
        return urlRequest
    }
    
    func createPostTweetRequest(tweetBody: String) -> URLRequest? {
        var params = [(key: "oauth_consumer_key", value: apiKey),
                      (key: "oauth_nonce", value: oauthNonce),
                      (key: "oauth_signature_method", value: oauthSignatureMethod),
                      (key: "oauth_timestamp", value: oauthTimeStamp),
                      (key: "oauth_token", value: accessToken),
                      (key: "oauth_version", value: oauthVersion)]
            .map { (key: $0.key, value: $0.value.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!) }
        params.append((key: "status", value: tweetBody))
        params.append((key: "oauth_signature", value: createSignature(params: params, requestMethod: "POST", apiUrl: postTweetApiUrl)))
        
        let headerParams = params
            .map { [$0.key.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!,
                    $0.value.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!]
                .joined(separator: "=") }
            .joined(separator: ",")
        let headerValue = "OAuth " + headerParams
        
        guard let apiUrlObj = URL(string: postTweetApiUrl),
            var components = URLComponents(url: apiUrlObj, resolvingAgainstBaseURL: apiUrlObj.baseURL != nil) else {return nil}
        components.queryItems = [URLQueryItem(name: "status", value: tweetBody)]
        guard let requestFullPath = components.url else { return nil }
        var urlRequest = URLRequest(url: requestFullPath,
                                    cachePolicy: .reloadIgnoringLocalCacheData,
                                    timeoutInterval: 5)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue(headerValue, forHTTPHeaderField: "Authorization")
        
        return urlRequest
    }
    
    private func makeAuthorizationValue() -> String {
        var params = [(key: "oauth_consumer_key", value: apiKey),
                      (key: "oauth_signature_method", value: oauthSignatureMethod),
                      (key: "oauth_timestamp", value: oauthTimeStamp),
                      (key: "oauth_nonce", value: oauthNonce),
                      (key: "oauth_version", value: oauthVersion)]
            .map { (key: $0.key, value: $0.value.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!) }
        params.append((key: "oauth_callback", value: oauthCallBackUrl))
        params.append((key: "oauth_signature", value: createSignature(params: params, requestMethod: "POST", apiUrl: requestTokenApiUrl)))
        
        let headerParams = params
            .map { [$0.key.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!,
                    $0.value.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!]
                .joined(separator: "=") }
            .joined(separator: ",")
        
        let headerValuePrefix = "OAuth "
        return headerValuePrefix + headerParams
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
    
    func createSignatureBody(params: [(key: String, value: String)]) -> String {
        return params.sorted{ $0.key < $1.key }
            .map { [$0.key.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!,
                    $0.value.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!]
                .joined(separator: "=") }
            .joined(separator: "&")
            .addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!
    }
}
