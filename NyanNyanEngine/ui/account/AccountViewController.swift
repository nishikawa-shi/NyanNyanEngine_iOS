//
//  AccountViewController.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 9/16/19.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class AccountViewController: UIViewController {
    private let input: AccountViewModelInput
    private let output: AccountViewModelOutput
    private let disposeBag = DisposeBag()
    
    @IBOutlet weak var noticeToast: UILabel!
    //TODO: まともなUIのボタンができたら消す
    @IBAction func logoutButtonTapped(_ sender: Any) {
        present(self.createLogoutActionSheet(), animated: true, completion: nil)
    }
    
    //ストーリーボードから呼ばれることが前提のクラスなので、こちらのイニシャライザは呼ばれない想定
    init(viewModel: AccountViewModelInput & AccountViewModelOutput = AccountViewModel()) {
        self.input = viewModel
        self.output = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        let viewModel = AccountViewModel()
        self.input = viewModel
        self.output = viewModel
        super.init(coder: aDecoder)
    }
    
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        output.isLoading
            .subscribe() { [unowned self] in
                ($0.element ?? false) ? self.activityIndicator.startAnimating() : self.activityIndicator.stopAnimating()
        }.disposed(by: disposeBag)
        
        output.logoutSucceeded?
            .map { return $0 ? R.string.stringValues.logout_pop_succeeded() : R.string.stringValues.logout_pop_failed() }
            .subscribe { [unowned self] in
                guard let message = $0.element else { return }
                self.popNoticeToast(message: message)
            }
            .disposed(by: disposeBag)
    }
    
    private func createLogoutActionSheet() -> UIAlertController {
        let alert = UIAlertController(title: R.string.stringValues.logout_sheet_title(),
                                      message: R.string.stringValues.logout_sheet_body(),
                                      preferredStyle:  .actionSheet)
        let logout = UIAlertAction(title: R.string.stringValues.logout_sheet_exec(), style: .destructive) { [unowned self] _ in
            self.input.logoutExecutedAt?.onNext("nya-on")
        }
        let cancel = UIAlertAction(title: R.string.stringValues.logout_sheet_cancel(), style: .default)

        alert.addAction(logout)
        alert.addAction(cancel)
        return alert
    }
    
    private func popNoticeToast(message: String) {
        self.noticeToast.text = message
        
        self.noticeToast.alpha = 0.0
        self.noticeToast.isHidden = false
        UIView.animate(withDuration: 0.5, animations: { [unowned self] in
            self.noticeToast.alpha = 1.0
        })
        
        DispatchQueue.main.asyncAfter(deadline: .now()+5.0) {
            UIView.animate(withDuration: 0.5,
                           animations: { [unowned self] in
                            self.noticeToast.alpha = 0.0
                           },
                           completion: { [unowned self] _ in
                            self.noticeToast.isHidden = true
                            self.noticeToast.alpha = 1.0
                            self.noticeToast.text = "にゃーおんにゃーおんにゃーおん\nにゃんにゃにゃ！"
                           })
        }
    }
}
