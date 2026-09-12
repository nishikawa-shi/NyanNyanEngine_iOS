//
//  PostNekogoViewModel.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/05/18.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

protocol PostNekogoViewModelInput: AnyObject {
    var originalTextChangedTo: AnyObserver<String?>? { get }
    var postExecutedAs: AnyObserver<String?>? { get }
}

protocol PostNekogoViewModelOutput: AnyObject {
    var nekogoText: Observable<String?> { get }
    var allowTweet: Observable<Bool> { get }
    var postSucceeded: Observable<String?> { get }
    var isLoading: Observable<Bool> { get }
}

final class PostNekogoViewModel: PostNekogoViewModelInput, PostNekogoViewModelOutput {
    private let tweetsRepository: BaseTweetsRepository
    private let authRepository: BaseAuthRepository
    private let loadingStatusRepository: BaseLoadingStatusRepository
    private let disposeBag = DisposeBag()
    
    var originalTextChangedTo: AnyObserver<String?>? = nil
    var postExecutedAs: AnyObserver<String?>? = nil
    
    var nekogoText: Observable<String?>
    let allowTweet: Observable<Bool>
    let postSucceeded: Observable<String?>
    let isLoading: Observable<Bool>
    
    init(tweetsRepository: BaseTweetsRepository = TweetsRepository.shared,
         authRepository: BaseAuthRepository = AuthRepository.shared,
         loadingStatusRepository: BaseLoadingStatusRepository = LoadingStatusRepository.shared) {
        self.tweetsRepository = tweetsRepository
        self.authRepository = authRepository
        self.loadingStatusRepository = loadingStatusRepository
        
        let _nekogoText = BehaviorRelay<String?>(value: nil)
        self.nekogoText = _nekogoText.asObservable()
        let _allowTweet = BehaviorRelay<Bool>(value: false)
        self.allowTweet = _allowTweet.asObservable()
        self.postSucceeded = tweetsRepository.postedStatus
        self.isLoading = loadingStatusRepository.isLoading
        
        //selfを掴まないのは、この観測子を自分自身が保持しており、掴むと
        //画面を閉じてもViewModelが解放されなくなるため
        self.originalTextChangedTo = AnyObserver<String?> {
            guard let originalText = $0.element as? String else { return }
            _nekogoText.accept(Nekosan().createNekogo(sourceStr: originalText))
            _allowTweet.accept(authRepository.getLoggedInStatus() && originalText.isPostable)
        }
        
        self.postExecutedAs = AnyObserver<String?> {
            guard let labelValue = $0.element else { return }
            loadingStatusRepository.loadingStatusChangedTo.onNext(true)
            tweetsRepository.postExecutedAs?.onNext(labelValue)
        }
        
        //selfを掴まないのは、購読を保持するのがシングルトンのリポジトリ側であり、
        //掴むと画面を閉じたあともこの画面が投稿へ反応し続けるため。反応するたびに
        //タイムラインを取りに行くので、残った画面の数だけ課金される。
        //掴まなくても購読はこのクラスのDisposeBagに入っており、画面と一緒に畳まれる
        self.tweetsRepository.postedStatus.subscribe { _ in
            loadingStatusRepository
                .loadingStatusChangedTo
                .onNext(true)

            tweetsRepository
                .buttonRefreshExecutedAt?
                //消灯をこの画面に持たせないのは、投稿が成功すると画面が閉じ、
                //取得が終わる前に解放されるため。取りこぼすと共有のインジケータが
                //回ったままになる
                .onNext() {
                    loadingStatusRepository.loadingStatusChangedTo.onNext(false)
            }
        }
        .disposed(by: self.disposeBag)
    }
}

//判定の主語を文字列の側に置いているのは、ViewModelのメソッドにすると
//ViewModel自身が有効かを問うているように読めるため
private extension String {
    //案内文のままを弾くのは、まだ何も打っていない状態を打った内容として扱うと、
    //案内文がそのまま猫語になって投稿されるため
    var isPostable: Bool {
        return self != R.string.stringValues.default_post_original_text() && !self.isEmpty
    }
}
