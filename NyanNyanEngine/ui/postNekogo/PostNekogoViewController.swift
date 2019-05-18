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
    
    @IBOutlet weak var originalText: UITextView!
    @IBOutlet weak var nekogoText: UILabel!
    @IBOutlet weak var tweetButton: UIButton!
    
    @IBAction func touchCancelAction(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.originalText.delegate = self

        originalText.rx.text
            .bind(to: input.originalTextChangedTo!)
            .disposed(by: disposeBag)
        
        tweetButton.rx.tap
            .map { [unowned self] in
                self.dismiss(animated: true, completion: nil)
            }
            .subscribe()
            .disposed(by: disposeBag)
        
        output.nekogoText
            .bind(to: nekogoText.rx.text)
            .disposed(by: disposeBag)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

extension PostNekogoViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        DispatchQueue.main.async {
            textView.selectAll(nil)
        }
    }
}
