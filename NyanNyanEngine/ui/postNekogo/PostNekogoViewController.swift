//
//  PostNekogoViewController.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/05/17.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class PostNekogoViewController: UIViewController {
    private let input: PostNekogoViewModelInput
    private let output: PostNekogoViewModelOutput
    private let disposeBag = DisposeBag()
    
    //ストーリーボードから呼ばれることが前提のクラスなので、こちらのイニシャライザは呼ばれない想定
    init(viewModel: PostNekogoViewModelInput & PostNekogoViewModelOutput = PostNekogoViewModel()) {
        self.input = viewModel
        self.output = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        let viewModel = PostNekogoViewModel()
        self.input = viewModel
        self.output = viewModel
        super.init(coder: aDecoder)
    }
    
    @IBOutlet private weak var originalText: UITextView!
    @IBOutlet private weak var nekogoText: UILabel!
    @IBOutlet private weak var tweetButton: UIButton!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    @IBAction private func touchCancelAction(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.originalText.delegate = self
        //Storyboard上の指定だと、なぜかlocalizeが反映されないので、ここで指定する。
        self.originalText.text = R.string.stringValues.default_post_original_text()
        
        originalText.rx.text
            .bind(to: input.originalTextChangedTo!)
            .disposed(by: disposeBag)
        
        tweetButton.rx.tap
            .map { [unowned self] in self.nekogoText.text }
            .bind(to: self.input.postExecutedAs!)
            .disposed(by: disposeBag)
        
        output.nekogoText
            .bind(to: nekogoText.rx.text)
            .disposed(by: disposeBag)
        
        output.postSucceeded
            .subscribe { [unowned self] _ in self.dismiss(animated: true, completion: nil)}
            .disposed(by: disposeBag)
        
        output.allowTweet
            .subscribe { [unowned self] in self.setButtonStatus(enabled: $0.element ?? false) }
            .disposed(by: disposeBag)
        
        output.isLoading
            .subscribe() { [unowned self] in
                ($0.element ?? false) ? self.activityIndicator.startAnimating() : self.activityIndicator.stopAnimating()
        }
        .disposed(by: disposeBag)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    private func setButtonStatus(enabled: Bool) {
        self.tweetButton.isEnabled = enabled
        self.tweetButton.backgroundColor = enabled ?
            UIColor(red: 0.1484375, green: 0.54296875, blue: 0.8203125, alpha: 1.0) : UIColor(red: 0.51171875, green: 0.578125, blue: 0.5859375, alpha: 1)
    }
}

extension PostNekogoViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        DispatchQueue.main.async {
            textView.selectAll(nil)
        }
    }
}
