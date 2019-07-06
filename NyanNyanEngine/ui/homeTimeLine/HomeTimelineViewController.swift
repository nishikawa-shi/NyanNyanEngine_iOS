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
import SafariServices
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
    
    @IBOutlet weak var navigationBar: UINavigationItem!
    @IBOutlet weak var authButton: UIBarButtonItem!
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    @IBOutlet weak var tweetList: UITableView!
    @IBOutlet weak var noticeToast: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.registerAddToSiriActivity()
        
        authButton.rx.tap
            .throttle(DispatchTimeInterval.seconds(3), latest: false, scheduler: ConcurrentMainScheduler.instance)
            .map { "0000/01/01 00:00:00" }
            .bind(to: input.authExecutedAt!)
            .disposed(by: disposeBag)
        
        refreshButton.rx.tap
            .map { [unowned self] in self.scrollTweetListToTop() }
            .throttle(DispatchTimeInterval.seconds(3), latest: false, scheduler: ConcurrentMainScheduler.instance)
            .map { "9999/12/31 23:59:59" }
            .bind(to: input.buttonRefreshExecutedAt!)
            .disposed(by: disposeBag)
        
        tweetList.rx.itemSelected
            .bind(to: input.cellTapExecutedOn!)
            .disposed(by: disposeBag)
        
        let prefetchRatio = 0.6
        tweetList.rx.contentOffset
            .filter { $0.y > (self.tweetList.frame.size.height * CGFloat(prefetchRatio))}
            .throttle(DispatchTimeInterval.seconds(3), latest: false, scheduler: ConcurrentMainScheduler.instance)
            .map { _ in return "9999/12/31 23:59:59" }
            .bind(to: input.infiniteScrollExecutedAt!)
            .disposed(by: disposeBag)
        
        let tweetObservable = output.nyanNyanStatuses
            .flatMap{ $0.flatMap { Observable<[NyanNyan]>.just($0) } ?? Observable<[NyanNyan]>.empty() }
            .map { NyanNyanSection(items: $0, idSuffix: "main") }

        let loadingObservable = output.isInfiniteLoading
            .map { $0 ? [NyanNyan(profileUrl: nil,
                userName: "LoadingName",
                userId: "LoadingId",
                nyanedAt: "LoadingNyan",
                nekogo: "LoadingNekogo",
                ningengo: "LoadingNingengo",
                isNekogo: true)] : []}
            .map { NyanNyanSection(items: $0, idSuffix: "infiniteLoading") }

        Observable.combineLatest(tweetObservable, loadingObservable)
            .map { return [$0, $1] }
            .bind(to: tweetList.rx.items(dataSource: DataSourceFactory.shared.createTweetSummary()))
            .disposed(by: disposeBag)
        
        output.currentUser
            .bind(to: navigationBar.rx.title)
            .disposed(by: disposeBag)
        
        output.isLoading
            .subscribe() { [unowned self] in
                ($0.element ?? false) ? self.activityIndicator.startAnimating() : self.activityIndicator.stopAnimating()
            }.disposed(by: disposeBag)
        
        output.isLoggedIn?
            .map { !$0 }
            .bind(to: authButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        output.authPageUrl?
            .subscribe { [unowned self] in
                guard let pageUrl = $0.element as? URL else { return }
                let sFSafariViewController = SFSafariViewController(url: pageUrl)
                if #available(iOS 11.0, *) {
                    sFSafariViewController.dismissButtonStyle = .cancel
                }
                
                self.present(sFSafariViewController,
                             animated: true,
                             completion: nil)
            }.disposed(by: disposeBag)
        
        output.postSucceeded
            .subscribe { [unowned self] in
                guard let text = $0.element as? String else { return }
                self.popNoticeToast(message: text)
            }
            .disposed(by: disposeBag)
        
        tweetList.refreshControl = UIRefreshControl()
        tweetList.refreshControl?.addTarget(self, action: #selector(self.refresh(sender:)), for: .valueChanged)
        tweetList.rowHeight = UITableView.automaticDimension
        
        input.buttonRefreshExecutedAt?.onNext("2019/04/30 12:12:12")
    }
    
    @objc func refresh(sender: UIRefreshControl) {
        input.pullToRefreshExecutedAt?.onNext(sender)
    }
    
    private func registerAddToSiriActivity() {
        if #available(iOS 12.0, *) {
            NSUserActivity.deleteAllSavedUserActivities { [unowned self] in
                self.addToSiriActivity.isEligibleForSearch = true
                self.addToSiriActivity.isEligibleForPrediction = true
                
                self.addToSiriActivity.title = R.string.stringValues.siri_title()
                self.addToSiriActivity.suggestedInvocationPhrase = R.string.stringValues.siri_suggested_invocation_phrase()
                let attributes = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
                attributes.contentDescription = R.string.stringValues.siri_content_description()
                attributes.thumbnailData = UIImage(named: "NyanNyaSensei")?.pngData()
                
                self.addToSiriActivity.contentAttributeSet = attributes
                self.userActivity = self.addToSiriActivity
            }
        }
    }
    
    private func scrollTweetListToTop() {
        if (self.tweetList.numberOfRows(inSection: 0) <= 0) {
            return
        }
        self.tweetList.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }
    
    private func popNoticeToast(message: String) {
        self.noticeToast.text = message
        
        self.noticeToast.alpha = 0.0
        self.noticeToast.isHidden = false
        UIView.animate(withDuration: 0.5, animations: { [unowned self] in
            self.noticeToast.alpha = 1.0
        })
        
        DispatchQueue.main.asyncAfter(deadline: .now()+5.0) {
            UIView.animate(withDuration: 0.5, animations: { [unowned self] in
                self.noticeToast.alpha = 0.0
                }, completion: { [unowned self] _ in
                    self.noticeToast.isHidden = true
                    self.noticeToast.alpha = 1.0
                    self.noticeToast.text = "にゃーおんにゃーおんにゃーおん\nにゃんにゃにゃ！"
            })
        }
    }
}
