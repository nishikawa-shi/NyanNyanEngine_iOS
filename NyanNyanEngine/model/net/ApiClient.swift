//
//  HttpClient.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/05/01.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation
import RxSwift
import Alamofire

protocol BaseApiClient: AnyObject {
    func getResponse(url: String) -> Observable<Data?>
    func postResponse(urlRequest: URLRequest) -> Observable<Data?>
}

class ApiClient: BaseApiClient {
    static let shared = ApiClient()
    private init() { }
    
    func getResponse(url: String) -> Observable<Data?> {
        return self.getRequest(url: url)
            .map { $0.value?.data(using: .utf8) }
    }
    
    func postResponse(urlRequest: URLRequest) -> Observable<Data?> {
        return self.postRequest(urlRequest: urlRequest)
            .map { $0.value?.data(using: .utf8) }
    }
    
    private func getRequest(url: String) -> Observable<DataResponse<String>> {
        guard let urlRequest = self.createGetUrlRequest(url: url) else { return Observable<DataResponse<String>>.empty() }
        
        return Observable<DataResponse<String>>.create { observer in
            Alamofire
                .request(urlRequest)
                .responseString(encoding: .utf8) { observer.onNext($0) }
            return Disposables.create()
        }
    }
    
    private func postRequest(urlRequest: URLRequest) -> Observable<DataResponse<String>> {
        return Observable<DataResponse<String>>.create { observer in
            Alamofire
                .request(urlRequest)
                .responseString(encoding: .utf8) { observer.onNext($0) }
            return Disposables.create()
        }
    }
    
    private func createGetUrlRequest(url: String) -> URLRequest? {
        guard let urlObj = URL(string: url) else { return nil }
        
        var urlRequest = URLRequest(url: urlObj,
                                    cachePolicy: .reloadIgnoringLocalCacheData,
                                    timeoutInterval: 5)
        urlRequest.httpMethod = HTTPMethod.get.rawValue
        
        return urlRequest
    }
}
