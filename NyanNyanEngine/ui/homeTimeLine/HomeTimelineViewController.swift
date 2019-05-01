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
    
    @IBOutlet weak var testLabel: UILabel!
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    @IBOutlet weak var tweetList: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshButton.rx.tap
            .map { "9999/12/31 23:59:59" }
            .bind(to: input.refreshExecutedAt!)
            .disposed(by: disposeBag)
        
        output.statuses
            .map { $0?.first?.text ?? "shippai"}
            .bind(to: testLabel.rx.text)
            .disposed(by: disposeBag)
        
        output.statuses
            .flatMap{ $0.flatMap { Observable<[Status]>.just($0) } ?? Observable<[Status]>.empty() }
            .bind(to: tweetList.rx.items(dataSource: TweetSummaryDataSource()))
            .disposed(by: disposeBag)
        
        input.refreshExecutedAt?.onNext("2019/04/30 12:12:12")
    }
}

