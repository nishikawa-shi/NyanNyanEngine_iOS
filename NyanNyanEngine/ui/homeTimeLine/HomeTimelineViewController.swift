//
//  ViewController.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/04/28.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import IntentsUI
import CoreSpotlight
import MobileCoreServices

class HomeTimelineViewController: UIViewController {
    private let addToSiriActivity = NSUserActivity(activityType: "com.ntetz.ios.NyanNyanEngine.homeTimeline")
    private let input: HomeTimelineViewModelInput
    private let output: HomeTimelineViewModelOutput
    private let disposeBag = DisposeBag()

    //ストーリーボードから呼ばれることが前提のクラスなので、こちらのイニシャライザは呼ばれない想定
    init(viewModel: HomeTimelineViewModelInput & HomeTimelineViewModelOutput = HomeTimelineViewModel()) {
        self.input = viewModel
        self.output = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        let viewModel = HomeTimelineViewModel()
        self.input = viewModel
        self.output = viewModel
        super.init(coder: aDecoder)
    }

    @IBOutlet private weak var navigationBar: UINavigationItem!
    @IBOutlet private weak var authButton: UIBarButtonItem!
    @IBOutlet private weak var tweetList: UITableView!
    @IBOutlet private weak var noticeToast: UILabel!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureTweetList()
        self.registerAddToSiriActivity()

        authButton.rx.tap
            .throttle(DispatchTimeInterval.seconds(3), latest: false, scheduler: ConcurrentMainScheduler.instance)
            .compactMap { [weak self] _ -> AuthorizationSheetPresenter? in self }
            .bind(to: input.authExecutedAt!)
            .disposed(by: disposeBag)

        tweetList.rx.itemSelected
            .bind(to: input.cellTapExecutedOn!)
            .disposed(by: disposeBag)

        output.nyanNyanStatuses
            .flatMap{ $0.flatMap { Observable<[NyanNyan]>.just($0) } ?? Observable<[NyanNyan]>.empty() }
            .map { [NyanNyanSection(items: $0)] }
            .bind(to: tweetList.rx.items(dataSource: DataSourceFactory.shared.createTweetSummary()))
            .disposed(by: disposeBag)

        output.listScrollUpExecuted
            .subscribe { [weak self] _ in self?.scrollTweetListToTop() }
            .disposed(by: disposeBag)

        output.currentAccount
            .map { $0.headerName }
            .bind(to: navigationBar.rx.title)
            .disposed(by: disposeBag)

        output.isLoading
            .subscribe { [weak self] in
                ($0.element ?? false) ? self?.activityIndicator.startAnimating() : self?.activityIndicator.stopAnimating()
        }
        .disposed(by: disposeBag)

        output.isLoggedIn?
            .map { !$0 }
            .bind(to: authButton.rx.isEnabled)
            .disposed(by: disposeBag)

        output.postSucceeded
            .subscribe { [weak self] in
                guard let self = self, let text = $0.element as? String else { return }
                self.input.useMultiplierValue { [weak self] multiplier in
                    let pointStr = String(NekosanRank.getNekosanPoint(nekogoStr: text) * multiplier)
                    let newMessage = [pointStr,
                                      R.string.stringValues.post_point_original_text(),
                                      text].joined()
                    self?.popNoticeToast(message: newMessage)
                }
        }
        .disposed(by: disposeBag)

        input.buttonRefreshExecutedAt?.onNext("2019/04/30 12:12:12")
    }

    //インジケータを1秒残してから止めるのは、応答が速すぎると引っ張った手応えが
    //出ないため。待ちをmodel層のsleepで作らないのは、応答がメインスレッドへ
    //届くため、その場で眠ると画面ごと1秒止まるため
    @objc func refresh(sender: UIRefreshControl) {
        input.pullToRefreshExecutedAt?.onNext { [weak sender] in
            DispatchQueue.main.asyncAfter(deadline: .now()+1.0) { sender?.endRefreshing() }
        }
    }

    private func configureTweetList() {
        tweetList.register(UINib(nibName: "TweetSummaryCell", bundle: nil), forCellReuseIdentifier: "TweetSummaryCell")
        tweetList.tableFooterView = UIView()
        tweetList.refreshControl = UIRefreshControl()
        tweetList.refreshControl?.addTarget(self, action: #selector(self.refresh(sender:)), for: .valueChanged)
        tweetList.rowHeight = UITableView.automaticDimension
    }

    private func registerAddToSiriActivity() {
        if #available(iOS 12.0, *) {
            NSUserActivity.deleteAllSavedUserActivities { [weak self] in
                guard let self = self else { return }
                self.addToSiriActivity.isEligibleForSearch = true
                self.addToSiriActivity.isEligibleForPrediction = true

                self.addToSiriActivity.title = R.string.stringValues.siri_title()
                self.addToSiriActivity.suggestedInvocationPhrase = R.string.stringValues.siri_suggested_invocation_phrase()
                let attributes = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
                attributes.contentDescription = R.string.stringValues.siri_content_description()
                attributes.thumbnailData = UIImage(named: "NyanNyaSensei")?.pngData()

                self.addToSiriActivity.contentAttributeSet = attributes
                DispatchQueue.main.async { [weak self] in
                    self?.userActivity = self?.addToSiriActivity
                }
            }
        }
    }

    private func scrollTweetListToTop() {
        if (self.tweetList.numberOfSections <= 0) {
            return
        }
        if (self.tweetList.numberOfRows(inSection: 0) <= 0) {
            return
        }
        self.tweetList.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }

    private func popNoticeToast(message: String) {
        self.noticeToast.text = message

        self.noticeToast.alpha = 0.0
        self.noticeToast.isHidden = false
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            self?.noticeToast.alpha = 1.0
        })

        DispatchQueue.main.asyncAfter(deadline: .now()+5.0) { [weak self] in
            UIView.animate(withDuration: 0.5, animations: { [weak self] in
                self?.noticeToast.alpha = 0.0
                }, completion: { [weak self] _ in
                    self?.noticeToast.isHidden = true
                    self?.noticeToast.alpha = 1.0
                    self?.noticeToast.text = "にゃーおんにゃーおんにゃーおん\nにゃんにゃにゃ！"
            })
        }
    }
}

//準拠を画面の側に置くのは、自分が提示元になれることを知っているのが
//画面自身のため。model側からUIViewControllerを名指しせずに済む
extension HomeTimelineViewController: AuthorizationSheetPresenter {
    var viewControllerForAuthorizationSheet: UIViewController { return self }
}
