//
//  AccountViewController.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 9/16/19.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import UIKit

class AccountViewController: UIViewController {
    private let input: AccountViewModelInput
    private let output: AccountViewModelOutput
    
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
    
    private func execLogout() {
        self.input.logoutExecutedAt?.onNext("nya-on")
    }
}
