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
}

class ApiRequestFactory: BaseApiRequestFactory {
    private let apiKey: String
    private let apiSecret: String
    private let oauthTimeStamp: String
    private let oauthNonce: String
    
    private let allowedCharacterSet: CharacterSet
    
    private let oauthCallBackUrl = "https://rhenium.ntetz.com/nyan-nyan-engine/authorized"
    private let oauthSignatureMethod = "HMAC-SHA1"
    private let oauthVersion = "1.0"
    
    private let accessTokenSecret = ""
    private let requestTokenApiUrl = "https://api.twitter.com/oauth/request_token"
    
    init(apiKey: String = "abcdefghijklMNOPQRSTU0123",
         apiSecret: String = "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMN",
         oauthTimeStamp: String = "1234567890",
         oauthNonce: String = "0000") {
        self.apiKey = apiKey
        self.apiSecret = apiSecret
        self.oauthTimeStamp = oauthTimeStamp
        self.oauthNonce = oauthNonce
        
        var baseAllowed = CharacterSet.alphanumerics
        baseAllowed.insert(charactersIn: "-._~")
        self.allowedCharacterSet = baseAllowed
    }
    
    func createRequestTokenRequest() -> URLRequest? {
        guard let urlObj = URL(string: "https://nyannyanengine-ios-d.firebaseapp.com/oauth/request_token") else { return nil }
        var urlRequest = URLRequest(url: urlObj,
                                    cachePolicy: .reloadIgnoringLocalCacheData,
                                    timeoutInterval: 5)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue(makeAuthorizationValue(), forHTTPHeaderField: "Authorization")
        
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
        params.append((key: "oauth_signature", value: createSignature(params: params)))
        
        let headerParams = params
            .map { [$0.key.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!,
                    $0.value.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!]
                .joined(separator: "=") }
            .joined(separator: ",")
        
        let headerValuePrefix = "OAuth "
        return headerValuePrefix + headerParams
    }
    
    private func createSignature(params: [(key: String, value: String)]) -> String {
        let signatureKey = apiSecret.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!
            + "&"
            + accessTokenSecret.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!
        
        let requestMethod = "POST"
        let signatureData = [requestMethod.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!,
                             requestTokenApiUrl.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!,
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
