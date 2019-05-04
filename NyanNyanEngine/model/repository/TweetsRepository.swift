//
//  HomeTimelineRepository.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/05/01.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

protocol BaseTweetsRepository: AnyObject {
    func isLoggedIn() -> Bool
    func getHomeTimeLine(uiRefreshControl: UIRefreshControl?) -> Observable<[Status]?>
    func getCurrentUser() -> Observable<String>
    
    var statuses: Observable<[Status]?> { get }
    var buttonRefreshExecutedAt: AnyObserver<String>? { get }
    var pullToRefreshExecutedAt: AnyObserver<UIRefreshControl?>? { get }
}

class TweetsRepository: BaseTweetsRepository {
    static let shared = TweetsRepository()
    
    private let disposeBag = DisposeBag()
    private let apiClient: BaseApiClient
    private let userDefaultsConnector: BaseUserDefaultsConnector
    
    let statuses: Observable<[Status]?>
    var buttonRefreshExecutedAt: AnyObserver<String>? = nil
    var pullToRefreshExecutedAt: AnyObserver<UIRefreshControl?>? = nil

    private init(apiClient: BaseApiClient = ApiClient.shared,
                 userDefaultsConnector: BaseUserDefaultsConnector = UserDefaultsConnector.shared) {
        self.apiClient = apiClient
        self.userDefaultsConnector = userDefaultsConnector
        
        let _statuses = BehaviorRelay<[Status]?>(value: nil)
        self.statuses = _statuses.asObservable()
        
        self.buttonRefreshExecutedAt = AnyObserver<String> { [unowned self] updatedAt in
            self.getHomeTimeLine()
            .bind(to: _statuses)
            .disposed(by: self.disposeBag)
        }
        
        self.pullToRefreshExecutedAt = AnyObserver<UIRefreshControl?> { [unowned self] uiRefreshControl in
            self.getHomeTimeLine()
                .map {
                    sleep(1)
                    uiRefreshControl.element??.endRefreshing()
                    return $0 ?? []
                }
            .bind(to: _statuses)
            .disposed(by: self.disposeBag)
        }
    }
    
    func getHomeTimeLine(uiRefreshControl: UIRefreshControl? = nil) -> Observable<[Status]?> {
        guard let apiKey = PlistConnector.shared.getString(withKey: "apiKey"),
            let apiSecret = PlistConnector.shared.getString(withKey: "apiSecret"),
            let accessToken = UserDefaultsConnector.shared.getString(withKey: "oauth_token"),
            let accessTokenSecret = UserDefaultsConnector.shared.getString(withKey: "oauth_token_secret"),
            let urlRequest = ApiRequestFactory(apiKey: apiKey,
                                               apiSecret: apiSecret,
                                               oauthNonce: "0000",
                                               accessTokenSecret: accessTokenSecret,
                                               accessToken: accessToken).createHomeTimelineRequest() else {
                                                uiRefreshControl?.endRefreshing()
                                                return Observable<[Status]?>.empty() }
        
        return self.apiClient
            .postResponse(urlRequest: urlRequest)
            .map { [unowned self] in self.toStatuses(data: $0) }
    }
    
    func getCurrentUser() -> Observable<String> {
        let tekitou = userDefaultsConnector.getString(withKey: "screen_name") ?? "にゃんにゃんエンジン"
        return Observable<String>.create { observer in
            observer.onNext(tekitou)
            return Disposables.create()
        }
    }
    
    func isLoggedIn() -> Bool {
        return userDefaultsConnector.isRegistered(withKey: "oauth_token")
    }
    
    private func toStatuses(data: Data?) -> [Status]? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let d = data else { return nil }
        return try? decoder.decode([Status].self, from: d)
    }
}
