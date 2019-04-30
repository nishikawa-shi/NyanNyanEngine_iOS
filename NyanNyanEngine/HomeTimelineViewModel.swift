//
//  HomeTimelineViewModel.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/04/30.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Alamofire

protocol HomeTimelineViewModelInput: AnyObject {
    //TODO: 後々、日付型っぽいやつにする
    var refreshExecutedAt: AnyObserver<String>? { get }
}

protocol HomeTimelineViewModelOutput: AnyObject {
    var statuses: Observable<[Status]?> { get }
}

final class HomeTimelineViewModel: HomeTimelineViewModelInput, HomeTimelineViewModelOutput {
    private let disposeBag = DisposeBag()
    
    var refreshExecutedAt: AnyObserver<String>? = nil
    let statuses: Observable<[Status]?>
    
    init() {
        let _statuses = BehaviorSubject<[Status]?>(value: nil)
        self.statuses = _statuses.asObservable()
        
        self.refreshExecutedAt = AnyObserver<String>() { updatedAt in
            self.getResponse(url: "https://nyannyanengine-ios-d.firebaseapp.com/1.1/statuses/home_timeline.json")
                .map { [unowned self] in self.toResponseBody(dataResponse: $0) }
                .map { [unowned self] in self.toStatuses(data: $0) }
                .bind(to: _statuses)
                .disposed(by: self.disposeBag)
            print(updatedAt.element)
        }
    }
    
    func getResponse(url: String) -> Observable<DataResponse<String>> {
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
