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

class HomeTimelineViewController: UIViewController {
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
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        authButton.rx.tap
            .throttle(DispatchTimeInterval.seconds(3), latest: false, scheduler: ConcurrentMainScheduler.instance)
            .map { "0000/01/01 00:00:00" }
            .bind(to: input.authExecutedAt!)
            .disposed(by: disposeBag)
        
        refreshButton.rx.tap
            .throttle(DispatchTimeInterval.seconds(3), latest: false, scheduler: ConcurrentMainScheduler.instance)
            .map { "9999/12/31 23:59:59" }
            .bind(to: input.buttonRefreshExecutedAt!)
            .disposed(by: disposeBag)
        
        output.statuses
            .flatMap{ $0.flatMap { Observable<[Status]>.just($0) } ?? Observable<[Status]>.empty() }
            .bind(to: tweetList.rx.items(dataSource: TweetSummaryDataSource()))
            .disposed(by: disposeBag)
        
        output.currentUser
            .bind(to: navigationBar.rx.title)
            .disposed(by: disposeBag)
        
        output.isLoading
            .subscribe() { status in
                if (status.element ?? false) {
                    self.activityIndicator.startAnimating()
                } else {
                    self.activityIndicator.stopAnimating()
                }
        }.disposed(by: disposeBag)
        
        output.isLoggedIn?
            .map { !$0 }
            .bind(to: authButton.rx.isEnabled)
            .disposed(by: disposeBag)

        
        tweetList.refreshControl = UIRefreshControl()
        tweetList.refreshControl?.addTarget(self, action: #selector(self.refresh(sender:)), for: .valueChanged)
        
        input.buttonRefreshExecutedAt?.onNext("2019/04/30 12:12:12")
    }
    
    @objc func refresh(sender: UIRefreshControl) {
        input.pullToRefreshExecutedAt?.onNext(sender)
    }
}

