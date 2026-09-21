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
    var postedStatus: Observable<String?> { get }
    var listScrollUpExecuted: Observable<Bool>{ get }
    //終わったことを知らせる手段を受け取るのは、止めるべき部品を知っているのが
    //画面の側で、model層が画面部品の型を知る理由がないため
    func refreshTimeline(scrollingToTop: Bool, notifying notifyFinished: @escaping (() -> Void))
    func toggleNekogo(at indexPath: IndexPath)
    func post(nekogo: String)
}

class TweetsRepository: BaseTweetsRepository {
    static let shared = TweetsRepository()

    private let disposeBag = DisposeBag()
    private let userDefaultsConnector: BaseUserDefaultsConnector
    private let xAuthClient: BaseXAuthClient
    private let authRepository: BaseAuthRepository

    //何件取るかをここに置いているのは、読み取りが取得したツイート1件ごとに
    //課金されるため、支払い額を決める値が1か所から読めるようにするため。
    //Firestoreから配れるようにするのは従量課金の安全装置を入れるときで、
    //それまではアプリの更新なしに絞れない
    private let timelineCount = 10

    private let _statuses: BehaviorRelay<[NyanNyan]?>
    private let _listScrollUpExecuted: PublishRelay<Bool>
    private let _refreshRequested: PublishRelay<(() -> Void)>
    private let _postRequested: PublishRelay<String>

    let nyanNyanStatuses: Observable<[NyanNyan]?>
    let postedStatus: Observable<String?>
    let listScrollUpExecuted: Observable<Bool>

    //private init にしていないのは、テストが XAuthClient と AuthRepository を差し替えるため
    init(userDefaultsConnector: BaseUserDefaultsConnector = UserDefaultsConnector.shared,
         xAuthClient: BaseXAuthClient = XAuthClient.shared,
         authRepository: BaseAuthRepository = AuthRepository.shared) {
        self.userDefaultsConnector = userDefaultsConnector
        self.xAuthClient = xAuthClient
        self.authRepository = authRepository

        let _statuses = BehaviorRelay<[NyanNyan]?>(value: nil)
        self._statuses = _statuses
        self.nyanNyanStatuses = _statuses.asObservable()

        let _postedStatus = PublishRelay<String?>()
        self.postedStatus = _postedStatus.asObservable()

        let _listScrollUpExecuted = PublishRelay<Bool>()
        self._listScrollUpExecuted = _listScrollUpExecuted
        self.listScrollUpExecuted = _listScrollUpExecuted.asObservable()

        //要求をいったんRelayへ預けてから購読を1本だけ張るのは、要求のたびに
        //購読を作ると、このクラスがシングルトンでDisposeBagが解放されないため、
        //完了した購読が起動中ずっと積み上がるため
        let _refreshRequested = PublishRelay<(() -> Void)>()
        self._refreshRequested = _refreshRequested
        let _postRequested = PublishRelay<String>()
        self._postRequested = _postRequested

        _refreshRequested
            .flatMap { [weak self] notifyFinished -> Observable<[NyanNyan]?> in
                //取得を始められないときにも知らせるのは、知らせないままだと
                //画面が終わりを待ち続け、インジケータが回ったままになるため
                guard let self = self else {
                    notifyFinished()
                    return Observable<[NyanNyan]?>.empty()
                }
                return self.getHomeTimeLine()
                    .do(onNext: { _ in notifyFinished() })
            }
            //読めなかったときに手元の一覧を残すのは、取得できなかったことを
            //空の画面として見せると、ねこさんが居なくなったように見えるため
            .map { fetchedStatuses -> [NyanNyan] in
                guard let fetchedStatuses = fetchedStatuses,
                    !fetchedStatuses.isEmpty else { return _statuses.value ?? [] }
                return fetchedStatuses
            }
            .bind(to: _statuses)
            .disposed(by: self.disposeBag)

        _postRequested
            .flatMap { [weak self] nekosanTextBody -> Observable<String?> in
                guard let self = self else { return Observable<String?>.empty() }
                let decoratedBody = LocalSettingsRepository.HashTagTypes.allCases
                    .filter{LocalSettingsRepository.shared.getHashTagSetting(type: $0).isEnabled}
                    .map { $0.getTweetText() }
                    .reduce(nekosanTextBody) { [$0, $1].joined(separator: " ") }
                return self.postTweets(nekosanText: decoratedBody)
                    .map { postedText in
                        //届かなかった猫語にねこさんポイントを払わないのは、投稿していない
                        //回数ぶん階級が上がると、階級が投稿の記録として読めなくなるため
                        if let postedText = postedText {
                            self.authRepository.updateNyanNyanAccount(postedText: postedText)
                        }
                        //Observerの型をラムダ式ではなくStringにしたかったのでここでLoadingStatusRepositoryへの依存が生まれてしまっている。
                        //モジュール性が若干下がるので、構成を見直した方が良いかもしれない・・・
                        LoadingStatusRepository.shared.loadingStatusChangedTo.onNext(false)
                        //失敗をnilで伝えるのは、加算していないポイント額を「獲得した」と
                        //告げるトーストが出て、画面とFirestoreの値が食い違うため
                        return postedText == nil ? nil : nekosanTextBody
                }
            }
            .bind(to: _postedStatus)
            .disposed(by: self.disposeBag)
    }

    //先頭へ戻すかを引数で受け取るのは、取り直す中身がどちらも同じで、
    //違うのが取り終えたあとの見せ方だけのため
    func refreshTimeline(scrollingToTop: Bool, notifying notifyFinished: @escaping (() -> Void)) {
        if scrollingToTop {
            self._listScrollUpExecuted.accept(true)
        }
        self._refreshRequested.accept(notifyFinished)
    }

    func toggleNekogo(at indexPath: IndexPath) {
        var statuses = self._statuses.value
        statuses?[indexPath.row].isNekogo.toggle()
        self._statuses.accept(statuses)
    }

    func post(nekogo: String) {
        self._postRequested.accept(nekogo)
    }

    //自分のIDが要るのは、v2のホームタイムラインが「誰の」タイムラインかを
    //URLで名指しするため。手元に無いのは未ログインのときなので、
    //Xへ問い合わせず、にゃんにゃ先生に出てきてもらう
    private func getHomeTimeLine() -> Observable<[NyanNyan]?> {
        guard let userId = self.userDefaultsConnector.getString(withKey: "user_id"),
            let urlRequest = V2ApiRequestFactory.shared
                .createHomeTimelineRequest(userId: userId,
                                           maxResults: self.timelineCount) else {
                                            return Observable<[NyanNyan]?>.just(DefaultNekosan().nyanNyanStatuses)}

        return self.xAuthClient
            .executeAuthorizedRequest(urlRequest: urlRequest)
            .map { $0.toNyanNyan() }
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
}

//変換の主語を応答と一覧の側に置いているのは、リポジトリのメソッドにすると
//リポジトリそのものを猫語へ変換しているように読めるため。
//読めなかったときにnilを返すのは、空の一覧と区別するため。空を返すと
//「ねこさんが1匹も居ない」として手元の一覧が消える
private extension Result where Success == Data, Failure == ApiError {
    func toNyanNyan() -> [NyanNyan]? {
        guard case .success(let data) = self else { return nil }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return (try? decoder.decode(V2TimelineResponse.self, from: data))?.toNyanNyan()
    }
}

private extension V2TimelineResponse {
    //投稿者を辞書へ組み替えてから引くのは、v2がツイートと投稿者を別の場所へ
    //返し、突き合わせの手がかりがauthorIdしか無いため
    func toNyanNyan() -> [NyanNyan] {
        //同じidが二度現れても先に来た方を採るのは、重複で組み立てを止める
        //イニシャライザだと、応答の形が想定とずれた瞬間に落ちるため
        let authors = Dictionary((self.includes?.users ?? []).map { ($0.id, $0) },
                                 uniquingKeysWith: { firstAuthor, _ in firstAuthor })
        //投稿ごとに作らないのは、内側に抱えているRelativeDateTimeFormatterが
        //生成の重い型で、使い回す前提で持たせているため
        let postedAtFormatter = PostedAtFormatter()

        //投稿者を引き当てられないツイートを落としているのは、名前の欄を
        //埋める相手が居ないため。既定値で埋めるとにゃんにゃ先生の投稿として
        //並び、先生が言っていないことを言ったことになる
        return (self.data ?? []).compactMap { post in
            guard let author = post.authorId.flatMap({ authors[$0] }) else { return nil }
            return NyanNyan(id: post.id,
                            profileUrl: author.getFineImageUrl(),
                            userName: author.name,
                            userId: author.username,
                            nyanedAt: postedAtFormatter
                                .getNyanNyanTimeStamp(apiTimeStamp: post.createdAt ?? ""),
                            nekogo: Nekosan().createNekogo(sourceStr: post.text),
                            ningengo: post.text,
                            isNekogo: true)
        }
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
