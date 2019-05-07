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
    func executeHttpRequest(urlRequest: URLRequest) -> Observable<Data?>
}

class ApiClient: BaseApiClient {
    static let shared = ApiClient()
    private init() { }
    
    func executeHttpRequest(urlRequest: URLRequest) -> Observable<Data?> {
        return Observable<Data?>.create { observer in
            URLSession(configuration: .default)
                .dataTask(with: urlRequest) { data, _, _ in
                    DispatchQueue.main.sync { observer.onNext(data) }
                }.resume()
            return Disposables.create()
        }
    }
}
