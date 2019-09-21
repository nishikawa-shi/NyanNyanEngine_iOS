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
}
