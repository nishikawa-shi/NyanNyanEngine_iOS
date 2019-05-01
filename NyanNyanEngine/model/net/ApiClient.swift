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
}

class ApiClient: BaseApiClient {
    static let shared = ApiClient()
    private init() { }
    
    func getResponse(url: String) -> Observable<Data?> {
        return self.getRequest(url: url)
            .map { $0.value?.data(using: .utf8) }
    }
    
    private func getRequest(url: String) -> Observable<DataResponse<String>> {
        return Observable<DataResponse<String>>.create { observer in
            Alamofire
                .request(url, method: .get)
                .responseString(encoding: .utf8) { observer.onNext($0) }
            return Disposables.create()
        }
    }
}
