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
    var nyanNyanStatuses: Observable<[NyanNyan]?> { get }
    var postedStatus: Observable<Status?> { get }
    var buttonRefreshExecutedAt: AnyObserver<(() -> Void)>? { get }
    var pullToRefreshExecutedAt: AnyObserver<UIRefreshControl?>? { get }
    var postExecutedAs: AnyObserver<String?>? { get }
}

class TweetsRepository: BaseTweetsRepository {
    static let shared = TweetsRepository()
    
    private let disposeBag = DisposeBag()
    private let apiClient: BaseApiClient
    private let userDefaultsConnector: BaseUserDefaultsConnector
    
    let nyanNyanStatuses: Observable<[NyanNyan]?>
    let postedStatus: Observable<Status?>
    var buttonRefreshExecutedAt: AnyObserver<(() -> Void)>? = nil
    var pullToRefreshExecutedAt: AnyObserver<UIRefreshControl?>? = nil
    var postExecutedAs: AnyObserver<String?>? = nil
    
    private init(apiClient: BaseApiClient = ApiClient.shared,
                 userDefaultsConnector: BaseUserDefaultsConnector = UserDefaultsConnector.shared) {
        self.apiClient = apiClient
        self.userDefaultsConnector = userDefaultsConnector
        
        let _statuses = BehaviorRelay<[NyanNyan]?>(value: nil)
        self.nyanNyanStatuses = _statuses.asObservable()
        
        let _postedStatus = PublishRelay<Status?>()
        self.postedStatus = _postedStatus.asObservable()
        
        self.buttonRefreshExecutedAt = AnyObserver<(() -> Void)> { [unowned self] stopActivityIndicator in
            self.getHomeTimeLine()
                .map {
                    stopActivityIndicator.element?()
                    
                    guard let statusValueResponse = $0 else {
                        return _statuses.value ?? []
                    }
                    
                    if(statusValueResponse.isEmpty) {
                        return _statuses.value ?? []
                    }
                    
                    return statusValueResponse
                }
                .bind(to: _statuses)
                .disposed(by: self.disposeBag)
        }
        
        self.pullToRefreshExecutedAt = AnyObserver<UIRefreshControl?> { [unowned self] uiRefreshControl in
            self.getHomeTimeLine()
                .map {
                    sleep(1)
                    uiRefreshControl.element??.endRefreshing()
                    
                    guard let statusValueResponse = $0 else {
                        return _statuses.value ?? []
                    }
                    
                    if(statusValueResponse.isEmpty) {
                        return _statuses.value ?? []
                    }
                    
                    return statusValueResponse
                }
                .bind(to: _statuses)
                .disposed(by: self.disposeBag)
        }
        
        self.postExecutedAs = AnyObserver<String?> {
            guard let nekosanTextBody = $0.element as? String else { return }
            self.postTweets(nekosanText: nekosanTextBody)
                .map {
                    //Observerの型をラムダ式ではなくStringにしたかったのでここでLoadingStatusRepositoryへの依存が生まれてしまっている。
                    //モジュール性が若干下がるので、構成を見直した方が良いかもしれない・・・
                    LoadingStatusRepository.shared.loadingStatusChangedTo.onNext(false)
                    return $0 ?? Status(text: "にゃにゃーーーおん", createdAt: "99日前", user: User(name: "エラー猫さん", screenName: "neko_error", profileImageUrlHttps: nil))
                }
                .bind(to: _postedStatus)
                .disposed(by: self.disposeBag)
        }
    }
    
    private func getHomeTimeLine(uiRefreshControl: UIRefreshControl? = nil) -> Observable<[NyanNyan]?> {
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
                                                return Observable<[NyanNyan]?>.just(DefaultNekosan().nyanNyanStatuses)}
        
        return self.apiClient
            .executeHttpRequest(urlRequest: urlRequest)
            .map { [unowned self] in self.toStatuses(data: $0) }
            .map { [unowned self] in self.toNyanNyan(rawTweets: $0) }
    }
    
    private func postTweets(nekosanText: String) -> Observable<Status?> {
        guard let apiKey = PlistConnector.shared.getString(withKey: "apiKey"),
            let apiSecret = PlistConnector.shared.getString(withKey: "apiSecret"),
            let accessToken = UserDefaultsConnector.shared.getString(withKey: "oauth_token"),
            let accessTokenSecret = UserDefaultsConnector.shared.getString(withKey: "oauth_token_secret"),
            let urlRequest = ApiRequestFactory(apiKey: apiKey,
                                               apiSecret: apiSecret,
                                               oauthNonce: "0000",
                                               accessTokenSecret: accessTokenSecret,
                                               accessToken: accessToken)
                .createPostTweetRequest(tweetBody: nekosanText) else {
                    return Observable<Status?>.just(nil)
        }
        return self.apiClient
            .executeHttpRequest(urlRequest: urlRequest)
            .map { [unowned self] in self.toStatus(data: $0)}
    }
    
    private func toStatuses(data: Data?) -> [Status]? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let d = data else { return nil }
        return try? decoder.decode([Status].self, from: d)
    }
    
    private func toStatus(data: Data?) -> Status? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let d = data else { return nil }
        return try? decoder.decode(Status.self, from: d)
    }
    
    private func toNyanNyan(rawTweets: [Status]?) -> [NyanNyan] {
        return rawTweets?.map {
            NyanNyan(profileUrl: $0.user.profileImageUrlHttps,
                     userName: $0.user.name,
                     userId: ("@" + $0.user.screenName),
                     nyanedAt: TwitterDateFormatter().getNyanNyanTimeStamp(apiTimeStamp: $0.createdAt),
                     nekogo: Nekosan().createNekogo(sourceStr: $0.text))
        } ?? []
    }
}
