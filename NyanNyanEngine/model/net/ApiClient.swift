//
//  HttpClient.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/05/01.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation
import RxSwift

protocol BaseApiClient: AnyObject {
    func getResponse(url: String) -> Observable<Data?>
    func postResponse(urlRequest: URLRequest) -> Observable<Data?>
}

class ApiClient: BaseApiClient {
    static let shared = ApiClient()
    private init() { }
    
    func getResponse(url: String) -> Observable<Data?> {
        return self.getRequest(url: url)
    }
    
    func postResponse(urlRequest: URLRequest) -> Observable<Data?> {
        return Observable<Data?>.create { observer in
            URLSession(configuration: .default)
                .dataTask(with: urlRequest) { data, _, _ in
                    DispatchQueue.main.sync { observer.onNext(data) }
                }.resume()
            return Disposables.create()
        }
    }
    
    private func getRequest(url: String) -> Observable<Data?> {
        return Observable<Data?>.create { observer in
            guard let urlRequest = self.createGetUrlRequest(url: url) else { return Disposables.create() }
            
            URLSession(configuration: .default)
                .dataTask(with: urlRequest) { data, _, _ in
                    DispatchQueue.main.sync { observer.onNext(data) }
                }.resume()
            return Disposables.create()
        }
    }
    
    private func createGetUrlRequest(url: String) -> URLRequest? {
        guard let urlObj = URL(string: url) else { return nil }
        
        var urlRequest = URLRequest(url: urlObj,
                                    cachePolicy: .reloadIgnoringLocalCacheData,
                                    timeoutInterval: 5)
        urlRequest.httpMethod = "GET"
        
        return urlRequest
    }
}
