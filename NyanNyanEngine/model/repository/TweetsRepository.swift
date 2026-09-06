//
//  HomeTimelineRepository.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/05/01.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxRelay

protocol BaseTweetsRepository: AnyObject {
    var nyanNyanStatuses: Observable<[NyanNyan]?> { get }
    var postedStatus: Observable<String?> { get }
    var listScrollUpExecuted: Observable<Bool>{ get }
    var buttonRefreshExecutedAt: AnyObserver<(() -> Void)>? { get }
    var pullToRefreshExecutedAt: AnyObserver<UIRefreshControl?>? { get }
    var infiniteScrollExecutedAt: AnyObserver<(() -> Void)>? { get }
    var nekogoToggleExecutedAt: AnyObserver<IndexPath>? { get }
    var postExecutedAs: AnyObserver<String?>? { get }
}

class TweetsRepository: BaseTweetsRepository {
    static let shared = TweetsRepository()
    
    private let disposeBag = DisposeBag()
    private let apiClient: BaseApiClient
    private let userDefaultsConnector: BaseUserDefaultsConnector
    private let xAuthClient: BaseXAuthClient
    private let authRepository: BaseAuthRepository

    private var currentMinId = Int.max
    
    let nyanNyanStatuses: Observable<[NyanNyan]?>
    let postedStatus: Observable<String?>
    let listScrollUpExecuted: Observable<Bool>
    var buttonRefreshExecutedAt: AnyObserver<(() -> Void)>? = nil
    var pullToRefreshExecutedAt: AnyObserver<UIRefreshControl?>? = nil
    var infiniteScrollExecutedAt: AnyObserver<(() -> Void)>? = nil
    var nekogoToggleExecutedAt: AnyObserver<IndexPath>? = nil
    var postExecutedAs: AnyObserver<String?>? = nil
    
    //private init にしていないのは、テストが XAuthClient と AuthRepository を差し替えるため
    init(apiClient: BaseApiClient = ApiClient.shared,
         userDefaultsConnector: BaseUserDefaultsConnector = UserDefaultsConnector.shared,
         xAuthClient: BaseXAuthClient = XAuthClient.shared,
         authRepository: BaseAuthRepository = AuthRepository.shared) {
        self.apiClient = apiClient
        self.userDefaultsConnector = userDefaultsConnector
        self.xAuthClient = xAuthClient
        self.authRepository = authRepository

        let _statuses = BehaviorRelay<[NyanNyan]?>(value: nil)
        self.nyanNyanStatuses = _statuses.asObservable()
        
        let _postedStatus = PublishRelay<String?>()
        self.postedStatus = _postedStatus.asObservable()
        
        let _listScrollUpExecuted = PublishRelay<Bool>()
        self.listScrollUpExecuted = _listScrollUpExecuted.asObservable()
        
        self.buttonRefreshExecutedAt = AnyObserver<(() -> Void)> { [unowned self] stopActivityIndicator in
            _listScrollUpExecuted.accept(true)
            self.getHomeTimeLine()
                .map { [unowned self] in
                    stopActivityIndicator.element?()
                    
                    guard let statusValueResponse = $0 else {
                        return _statuses.value ?? []
                    }
                    self.updateMin(statuses: statusValueResponse)
                    
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
                .map { [unowned self] in
                    sleep(1)
                    uiRefreshControl.element??.endRefreshing()
                    
                    guard let statusValueResponse = $0 else {
                        return _statuses.value ?? []
                    }
                    
                    if(statusValueResponse.isEmpty) {
                        return _statuses.value ?? []
                    }
                    self.updateMin(statuses: statusValueResponse)
                    
                    return statusValueResponse
            }
            .bind(to: _statuses)
            .disposed(by: self.disposeBag)
        }
        
        self.infiniteScrollExecutedAt = AnyObserver<(() -> Void)> { stopActivityIndicator in
            let currentStatuses = _statuses.value ?? []
            self.getHomeTimeLine(maxId: String(self.currentMinId))
                .map { [unowned self] in
                    stopActivityIndicator.element?()
                    self.updateMin(statuses: $0)
                    guard var additive = $0 else { return $0 }
                    if(!additive.isEmpty) {
                        additive.removeFirst()
                    }
                    return additive
            }
            .map { currentStatuses + ($0 ?? []) }
            .bind(to: _statuses)
            .disposed(by: self.disposeBag)
        }
        
        self.nekogoToggleExecutedAt = AnyObserver<IndexPath> {
            guard let row = $0.element?.row else { return }
            var statuses = _statuses.value
            statuses?[row].isNekogo.toggle()
            _statuses.accept(statuses)
        }
        
        self.postExecutedAs = AnyObserver<String?> {
            guard let nekosanTextBody = $0.element as? String else { return }
            let decoratedBody = LocalSettingsRepository.HashTagTypes.allCases
                .filter{LocalSettingsRepository.shared.getHashTagSetting(type: $0).isEnabled}
                .map { $0.getTweetText() }
                .reduce(nekosanTextBody) { [$0, $1].joined(separator: " ") }
            self.postTweets(nekosanText: decoratedBody)
                .map { postedText in
                    //届かなかった猫語にねこさんポイントを払わないのは、投稿していない
                    //回数ぶん階級が上がると、階級が投稿の記録として読めなくなるため
                    if let postedText = postedText {
                        self.authRepository.updateNyanNyanAccount(postedText: postedText)
                    }
                    //Observerの型をラムダ式ではなくStringにしたかったのでここでLoadingStatusRepositoryへの依存が生まれてしまっている。
                    //モジュール性が若干下がるので、構成を見直した方が良いかもしれない・・・
                    LoadingStatusRepository.shared.loadingStatusChangedTo.onNext(false)
                    return nekosanTextBody
            }
            .bind(to: _postedStatus)
            .disposed(by: self.disposeBag)
        }
    }
    
    private func getHomeTimeLine(maxId: String? = nil,
                                 uiRefreshControl: UIRefreshControl? = nil) -> Observable<[NyanNyan]?> {
        guard let apiKey = PlistConnector.shared.getApiKey(),
            let apiSecret = PlistConnector.shared.getApiSecret(),
            let accessToken = UserDefaultsConnector.shared.getString(withKey: "oauth_token"),
            let accessTokenSecret = UserDefaultsConnector.shared.getString(withKey: "oauth_token_secret"),
            let urlRequest = ApiRequestFactory(apiKey: apiKey,
                                               apiSecret: apiSecret,
                                               oauthNonce: "0000",
                                               accessTokenSecret: accessTokenSecret,
                                               accessToken: accessToken).createHomeTimelineRequest(maxId: maxId) else {
                                                uiRefreshControl?.endRefreshing()
                                                return Observable<[NyanNyan]?>.just(DefaultNekosan().nyanNyanStatuses)}
        
        return self.apiClient
            .executeHttpRequest(urlRequest: urlRequest)
            .map { [unowned self] in self.toStatuses(data: $0) }
            .map { [unowned self] in self.toNyanNyan(rawTweets: $0) }
    }
    
    //投稿できたかをHTTPの成否だけで決め、採点する本文を別に決めているのは、
    //応答を読めなかったときに、投稿が成立した事実まで巻き添えで失わないため
    private func postTweets(nekosanText: String) -> Observable<String?> {
        guard let urlRequest = V2ApiRequestFactory.shared.createPostTweetRequest(tweetBody: nekosanText) else {
            return Observable<String?>.just(nil)
        }
        return self.xAuthClient
            .executeAuthorizedRequest(urlRequest: urlRequest)
            .map { $0.toPostedText(fallingBackTo: nekosanText) }
    }
    
    private func updateMin(statuses: [NyanNyan]?) {
        guard let statuses = statuses,
            let minId = statuses.map({$0.id}).min() else { return }
        if (minId < self.currentMinId) || (self.currentMinId == DefaultNekosan().nyanNyanStatuses[0].id) {
            self.currentMinId = minId
        }
    }
    
    private func toStatuses(data: Data?) -> [Status]? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let d = data else { return nil }
        return try? decoder.decode([Status].self, from: d)
    }
    
    private func toNyanNyan(rawTweets: [Status]?) -> [NyanNyan] {
        return rawTweets?.map {
            NyanNyan(id: $0.id,
                     profileUrl: $0.user.getFineImageUrl(),
                     userName: $0.user.name,
                     userId: $0.user.screenName,
                     nyanedAt: TwitterDateFormatter().getNyanNyanTimeStamp(apiTimeStamp: $0.createdAt),
                     nekogo: Nekosan().createNekogo(sourceStr: $0.text),
                     ningengo: $0.text,
                     isNekogo: true)
            } ?? []
    }
}

//この変換の主語は応答であって呼び出し元ではないため、Resultを受け手にしている。
//privateにしているのは、投稿の応答の読み方をこのファイルの外へ広げないため
private extension Result where Success == Data, Failure == ApiError {
    //読めなかったときに諦めず送った本文へ落ちるのは、投稿の成否をHTTPが既に
    //決めており、本文を読めないことを失敗として扱うと、Xに猫語が残ったまま
    //ポイントだけ消えるため。v2は値を持たない属性を応答へ書かない規約のため、
    //応答の形は将来も動きうる。属性ごとにオプショナルを増やさないのは、
    //どれが欠けてもデコードは同じように失敗し、ここ1か所で受け止めきれるため
    func toPostedText(fallingBackTo sentText: String) -> String? {
        guard case .success(let data) = self else { return nil }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return (try? decoder.decode(V2TweetResponse.self, from: data))?.data.text ?? sentText
    }
}
