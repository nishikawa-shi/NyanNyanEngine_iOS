//
//  AuthRepository.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/05/02.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation
import CryptoSwift
import RxSwift
import RxRelay

protocol BaseAuthRepository: AnyObject {
    func beginAuthorization(presenter: AuthorizationSheetPresenter,
                            modelUpdateLogic: @escaping(() -> Void) )
    func resumeAuthorization(with url: URL) -> Bool
    func authAppUser()
    func invalidateAccountInfo(modelUpdateLogic: @escaping(() -> Void) ) -> Observable<Bool>

    func getLoggedInStatus() -> Bool

    func updateNyanNyanAccount(postedStatus: Status)

    func useMultiplierValue(completion: @escaping ((Int) -> Void))

    var currentAccount: Observable<Account> { get }
    var currentNyanNyanAccount: Observable<NyanNyanUser> { get }
    var isLoggedIn: Observable<Bool>? { get }
    var logoutSucceeded: Observable<Bool>? { get }

    var accountUpdatedAt: AnyObserver<String>? { get }
}

class AuthRepository: BaseAuthRepository {
    static let shared = AuthRepository()

    private let disposeBag = DisposeBag()
    private let firebaseClient: BaseFirebaseClient
    private let userDefaultsConnector: BaseUserDefaultsConnector
    private let xAuthClient: BaseXAuthClient

    private let oauth1CredentialKeys = ["oauth_token",
                                        "oauth_token_secret"]

    let currentAccount: Observable<Account>
    private let _currentAccount: BehaviorRelay<Account>
    let currentNyanNyanAccount: Observable<NyanNyanUser>
    private let _currentNyanNyanAccount: BehaviorRelay<NyanNyanUser>
    var isLoggedIn: Observable<Bool>? = nil
    private let _isLoggedIn: BehaviorRelay<Bool>
    var logoutSucceeded: Observable<Bool>? = nil
    private let _logoutSucceeded: PublishRelay<Bool>

    var accountUpdatedAt: AnyObserver<String>? = nil

    //private init にしていないのは、テストが XAuthClient と UserDefaults を差し替えるため
    init(firebaseClient: BaseFirebaseClient = FirebaseClient.shared,
         userDefaultsConnector: BaseUserDefaultsConnector = UserDefaultsConnector.shared,
         xAuthClient: BaseXAuthClient = XAuthClient.shared) {
        self.firebaseClient = firebaseClient
        self.userDefaultsConnector = userDefaultsConnector
        self.xAuthClient = xAuthClient

        self._currentAccount = BehaviorRelay<Account>(value: Account())
        self.currentAccount = _currentAccount.asObservable()

        self._currentNyanNyanAccount = BehaviorRelay<NyanNyanUser>(value: NyanNyanUser())
        self.currentNyanNyanAccount = _currentNyanNyanAccount.asObservable()

        //self.getLoggedInStatusを呼ばず中身を直書きしているのは、全プロパティの
        //初期化が済むまでselfを使えないため
        self._isLoggedIn = BehaviorRelay<Bool>(value: xAuthClient.hasAuthorizedSession())
        self.isLoggedIn = _isLoggedIn.asObservable()

        self._logoutSucceeded = PublishRelay<Bool>()
        self.logoutSucceeded = _logoutSucceeded.asObservable()

        self.accountUpdatedAt = AnyObserver<String> { [unowned self] executedAt in
            self.getCurrentAccount()
                .bind(to: self._currentAccount)
                .disposed(by: self.disposeBag)

            self.getCurrentNyanNyanAccount()
                .bind(to: self._currentNyanNyanAccount)
                .disposed(by: self.disposeBag)
        }

        self.discardOAuth1CredentialsIfNeeded()
    }

    func beginAuthorization(presenter: AuthorizationSheetPresenter,
                            modelUpdateLogic: @escaping (() -> Void)) {
        self.xAuthClient.authorize(presenter: presenter) { [weak self] authorized in
            //認可されなかったときに何もしないのは、利用者が認可画面を閉じた場合と
            //失敗した場合が区別できず、閉じただけで画面が動くと驚きになるため
            guard authorized, let self = self else { return }
            self._isLoggedIn.accept(self.getLoggedInStatus())
            self.downloadMyAccount()
                .map { [weak self] in self?.saveUserInfo(user: $0) }
                .map (modelUpdateLogic)
                .subscribe()
                .disposed(by: self.disposeBag)
        }
    }

    //戻り先のURLがOS経由で届いたときに、進行中の認可へ渡す
    func resumeAuthorization(with url: URL) -> Bool {
        return self.xAuthClient.resumeAuthorization(with: url)
    }

    func invalidateAccountInfo(modelUpdateLogic: @escaping (() -> Void)) -> Observable<Bool> {
        return self.xAuthClient
            .revokeSession()
            .map { [unowned self] _ in self.deleteAccountInfo() }
            .map { [unowned self] in
                self._isLoggedIn.accept(self.getLoggedInStatus())
                //失効の成否をログアウトの成否として扱わないのは、Xへ届かなくても
                //端末からは消えており、利用者から見たログアウトは成立しているため
                self._logoutSucceeded.accept(true) }
            .map (modelUpdateLogic)
            .map { true }
    }

    func authAppUser() {
        self.firebaseClient.authAnonymously()
            .subscribe { [unowned self] event in
                guard let appUserId = event.element else { return }
                self.userDefaultsConnector.registerString(key: "app_user_id", value: appUserId)
        }.disposed(by: disposeBag)
    }

    func getLoggedInStatus() -> Bool {
        return self.xAuthClient.hasAuthorizedSession()
    }

    func useMultiplierValue(completion: @escaping ((Int) -> Void)) {
        self.firebaseClient.readDatabase(dbName: "config",
                                         key: "np_multiplier",
                                         completionHandler:{_, _ in})
            .subscribe { res in
                let multiplier = (res.element??["v"] as? Int) ?? 1
                completion(multiplier)
        }.disposed(by: disposeBag)
    }

    func updateNyanNyanAccount(postedStatus: Status) {
        guard let sealedTwitterId = self.userDefaultsConnector.getString(withKey: "user_id")?.md5() else { return }

        self.firebaseClient.readDatabase(dbName: "users", key: sealedTwitterId, completionHandler: { res, error in
            // 何らかの原因で、ネコさんアカウントができる前に投稿できてしまう現象があるらしいので、アカウント存在チェックをしている。
            if (res?.data() == nil) && (error == nil) {
                self.createNyanNyanAccount() { _ in
                    self.firebaseClient.readDatabase(dbName: "config",
                                                     key: "np_multiplier",
                                                     completionHandler:{_, _ in})
                        .subscribe { res in
                            let multiplier = (res.element??["v"] as? Int) ?? 1
                            let tweetNekosanPoint = NekosanRank.getNekosanPoint(nekogoStr: postedStatus.text)
                            let nekosanPoint = tweetNekosanPoint * multiplier
                            FirebaseClient.shared.incrementData(dbName: "users",
                                                                documentName: sealedTwitterId,
                                                                key: "np",
                                                                increaseValue: nekosanPoint) { [unowned self] _ in
                                                                    self.updateNyanNyanAccount()
                            }
                    }.disposed(by: self.disposeBag)
                }
                return
            }
            self.firebaseClient.readDatabase(dbName: "config",
                                             key: "np_multiplier",
                                             completionHandler:{_, _ in})
                .subscribe { res in
                    let multiplier = (res.element??["v"] as? Int) ?? 1
                    let tweetNekosanPoint = NekosanRank.getNekosanPoint(nekogoStr: postedStatus.text)
                    let nekosanPoint = tweetNekosanPoint * multiplier
                    FirebaseClient.shared.incrementData(dbName: "users",
                                                        documentName: sealedTwitterId,
                                                        key: "np",
                                                        increaseValue: nekosanPoint) { [unowned self] _ in
                                                            self.updateNyanNyanAccount()
                    }
            }.disposed(by: self.disposeBag)

        }).subscribe()
            .disposed(by: disposeBag)
    }

    private func getCurrentAccount() -> Observable<Account> {
        let defaultObservable = Observable<Account>.create {
            $0.onNext(Account())
            return Disposables.create()
        }

        if !self.getLoggedInStatus() {
            return defaultObservable
        }
        if !isAllAccountInfoFetched() {
            self.updateAccount()
        }
        guard let screenName = userDefaultsConnector.getString(withKey: "screen_name"),
            let headerName = userDefaultsConnector.getString(withKey: "screen_name"),
            let name = userDefaultsConnector.getString(withKey: "name"),
            let userId = userDefaultsConnector.getString(withKey: "user_id"),
            let profileImageUrl = userDefaultsConnector.getString(withKey: "profile_image_url_https") else {
                return defaultObservable
        }
        let user = User(id: userId, name: name, username: screenName, profileImageUrl: profileImageUrl)
        let account = Account(user: user, headerName: headerName)
        return Observable<Account>.create { observer in
            observer.onNext(account)
            return Disposables.create()
        }
    }

    private func updateAccount() {
        self.downloadMyAccount()
            .map { [weak self] user in
                guard let self = self, let user = user else { return }
                self.saveUserInfo(user: user)
                //ヘッダ名にusernameを使うのは、取得できた値だけでアカウント表示を
                //組み立てるため。UserDefaults側は保存が済んだ後でないと揃わない
                self._currentAccount.accept(Account(user: user, headerName: user.username))
        }
        .subscribe()
        .disposed(by: disposeBag)
    }

    private func downloadMyAccount() -> Observable<User?> {
        guard let urlRequest = V2ApiRequestFactory.shared.createMyAccountRequest() else {
            return Observable<User?>.just(nil)
        }
        return self.xAuthClient
            .executeAuthorizedRequest(urlRequest: urlRequest)
            .map { [weak self] result -> User? in
                guard let self = self else { return nil }
                self.discardSessionIfUnauthorized(result: result)
                return self.toUser(result: result)
        }
    }

    //401のまま戻るということは、リフレッシュも通らずX側で連携が切れている。
    //端末側を残すと、ログイン表示のまま何も取得できない状態が続く
    private func discardSessionIfUnauthorized(result: Result<Data, ApiError>) {
        guard case .failure(.unauthorized) = result else { return }
        self.xAuthClient.discardSession()
        self.deleteAccountInfo()
        self._isLoggedIn.accept(self.getLoggedInStatus())
    }

    private func getCurrentNyanNyanAccount() -> Observable<NyanNyanUser> {
        let defaultNyanNyanUser = NyanNyanUser(firestoreUserRecord: ["np": 99999, "tc": 0],
                                               firestoreDegreeRecords: ["0": ["nam": R.string.stringValues.settings_teacher_rank(),
                                                                              "pt": 0]])
        let defaultObservable = Observable<NyanNyanUser>.create {
            $0.onNext(defaultNyanNyanUser)
            return Disposables.create()
        }
        if !self.getLoggedInStatus() {
            return defaultObservable
        }

        guard let sealedTwitterId = self.userDefaultsConnector.getString(withKey: "user_id")?.md5() else {
            return Observable<NyanNyanUser>.empty()
        }

        return Observable.combineLatest(
            self.firebaseClient.readDatabase(dbName: "users", key: sealedTwitterId, completionHandler: { res, error in
                if (res?.data() == nil) && (error == nil) {
                    self.createNyanNyanAccount() {_ in}
                }
            }),
            self.firebaseClient.readDatabase(dbName: "config",
                                             key: R.string.stringValues.nekosan_rank_collection_name(),
                                             completionHandler: {_, _ in}))
            .map { users, rankConfig in
                NyanNyanUser(firestoreUserRecord: users,
                             firestoreDegreeRecords: rankConfig)
        }
    }

    private func updateNyanNyanAccount() {
        guard let sealedTwitterId = self.userDefaultsConnector.getString(withKey: "user_id")?.md5() else {
            return
        }
        Observable.combineLatest(
            self.firebaseClient.readDatabase(dbName: "users", key: sealedTwitterId, completionHandler: {_, _ in}),
            self.firebaseClient.readDatabase(dbName: "config",
                                             key: R.string.stringValues.nekosan_rank_collection_name(),
                                             completionHandler: {_, _ in})
        )
            .map {return NyanNyanUser(firestoreUserRecord: $0, firestoreDegreeRecords: $1)}
            .bind(to: self._currentNyanNyanAccount)
            .disposed(by: disposeBag)
    }

    private func createNyanNyanAccount(completionHandler: @escaping ((Error?)->Void)) {
        guard let sealedTwitterId = self.userDefaultsConnector.getString(withKey: "user_id")?.md5() else {
            return
        }
        self.firebaseClient.createData(dbName: "users", key: sealedTwitterId,
                                       data: ["np": 0, "tc": 0],
                                       completionHandler: completionHandler)
    }

    private func isAllAccountInfoFetched() -> Bool {
        let requiredKeys = ["screen_name",
                            "name",
                            "profile_image_url_https"]
        return requiredKeys.reduce(true) { [unowned self] (current: Bool, additive: String) -> Bool in
            return current && (self.userDefaultsConnector.getString(withKey: additive) != nil)
        }
    }

    private func toUser(result: Result<Data, ApiError>) -> User? {
        guard case .success(let data) = result else { return nil }
        let decorder = JSONDecoder()
        decorder.keyDecodingStrategy = .convertFromSnakeCase
        return (try? decorder.decode(V2UserResponse.self, from: data))?.data
    }

    private func saveUserInfo(user: User?) {
        guard let user = user else { return }
        let records = ["user_id": user.id,
                       "screen_name": user.username,
                       "name": user.name]
        records.forEach { [unowned self] in
            self.userDefaultsConnector.registerString(key: $0.key, value: $0.value)
        }
        //アイコンだけ分けているのは、値が無いときに空文字を保存すると
        //「取得済み」と見なされ、取り直しの機会を失うため
        guard let profileImageUrl = user.profileImageUrl else { return }
        self.userDefaultsConnector.registerString(key: "profile_image_url_https", value: profileImageUrl)
    }

    //1.6.2 までの版は、OAuth 1.0a の認証情報を UserDefaults に置いていた。
    //X側で失効済みのため、残っていると廃止された v1.1 を叩き続ける状態で
    //起動する。痕跡を見つけたら捨てて、未ログインからやり直してもらう
    private func discardOAuth1CredentialsIfNeeded() {
        let hasOAuth1Credentials = self.oauth1CredentialKeys
            .contains { self.userDefaultsConnector.getString(withKey: $0) != nil }
        guard hasOAuth1Credentials else { return }
        self.deleteAccountInfo()
    }

    //OAuth 1.0a の認証情報を最後に消すのは、これが「移行がまだ」の目印を
    //兼ねているため。先に消すと、途中で終了したときに残りを消しそびれた
    //まま、目印だけが失われる
    private func deleteAccountInfo() {
        let accountInfoKeys = ["user_id",
                               "screen_name",
                               "name",
                               "profile_image_url_https"]
        (accountInfoKeys + self.oauth1CredentialKeys).forEach {
            self.userDefaultsConnector.deleteRecord(forKey: $0)
        }
    }
}
