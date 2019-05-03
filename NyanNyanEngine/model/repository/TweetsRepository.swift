//
//  HomeTimelineRepository.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/05/01.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation
import RxSwift

protocol BaseTweetsRepository: AnyObject {
    func isLoggedIn() -> Bool
    func getHomeTimeLine() -> Observable<[Status]?>
}

class TweetsRepository: BaseTweetsRepository {
    static let shared = TweetsRepository()
    
    private let apiClient: BaseApiClient
    private let userDefaultsConnector: BaseUserDefaultsConnector
    
    private init(apiClient: BaseApiClient = ApiClient.shared,
                 userDefaultsConnector: BaseUserDefaultsConnector = UserDefaultsConnector.shared) {
        self.apiClient = apiClient
        self.userDefaultsConnector = userDefaultsConnector
    }
    
    func getHomeTimeLine() -> Observable<[Status]?> {
        return self.apiClient
            .getResponse(url: "https://nyannyanengine-ios-d.firebaseapp.com/1.1/statuses/home_timeline.json")
            .map { [unowned self] in self.toStatuses(data: $0) }
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
