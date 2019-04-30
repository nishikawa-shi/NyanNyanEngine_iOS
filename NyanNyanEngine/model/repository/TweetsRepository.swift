//
//  HomeTimelineRepository.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/05/01.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation
import Alamofire
import RxSwift

protocol BaseTweetsRepository: AnyObject {
    func getHomeTimeLine() -> Observable<[Status]?>
}

class TweetsRepository: BaseTweetsRepository {
    static let shared = TweetsRepository()
    
    private init() { }
    
    func getHomeTimeLine() -> Observable<[Status]?> {
        return self.getResponse(url: "https://nyannyanengine-ios-d.firebaseapp.com/1.1/statuses/home_timeline.json")
            .map { [unowned self] in self.toResponseBody(dataResponse: $0) }
            .map { [unowned self] in self.toStatuses(data: $0) }
    }
    
    private func getResponse(url: String) -> Observable<DataResponse<String>> {
        return Observable<DataResponse<String>>.create { observer in
            Alamofire.request(url, method: .get)
                .responseString(encoding: .utf8) { observer.onNext($0) }
            return Disposables.create()
        }
    }
    
    private func toResponseBody(dataResponse: DataResponse<String>) -> Data? {
        return dataResponse.value?.data(using: .utf8)
    }
    
    private func toStatuses(data: Data?) -> [Status]? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let d = data else { return nil }
        return try? decoder.decode([Status].self, from: d)
    }
    
}
