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
    private var account: Account?
    
    private let input: AccountViewModelInput
    private let output: AccountViewModelOutput
    private let disposeBag = DisposeBag()
    
    @IBOutlet weak var noticeToast: UILabel!
    
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
    
    @IBOutlet private weak var settingsList: UITableView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSettingsList()
        
        output.currentAccount
            .subscribe() { [unowned self] in
                self.account = $0.element
                self.settingsList.reloadData()
        }.disposed(by: disposeBag)
        
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
        let cancel = UIAlertAction(title: R.string.stringValues.logout_sheet_cancel(), style: .cancel)

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
    
    private func configureSettingsList() {
        settingsList.register(UINib(nibName: "AccountCell", bundle: nil), forCellReuseIdentifier: "AccountCell")
        settingsList.register(UINib(nibName: "LogoutCell", bundle: nil), forCellReuseIdentifier: "LogoutCell")
        settingsList.delegate = self
        settingsList.dataSource = self
    }
}

extension AccountViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let accountSection = 0
        let logoutRow = 1
        if indexPath.row == logoutRow && indexPath.section == accountSection {
            present(self.createLogoutActionSheet(), animated: true, completion: nil)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension AccountViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat{
        //キリが良さそうなので8の倍数にしてみた
        return 48
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let accountSection = 0
        
        let title: String
        switch section {
        case accountSection:
            title = R.string.stringValues.settings_header_acount()
            break
        default:
            title = ""
        }

        guard let view = UINib(nibName: "SettingsSectionHeader", bundle: nil)
            .instantiate(withOwner: nil, options: nil).first as? SettingsSectionHeader else { return nil }
        view.configure(title: title)
        return view
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let accountSection = 0
        let accountRow = 0
        let logoutRow = 1
        
        switch indexPath.section {
        case accountSection:
            switch indexPath.row {
            case accountRow:
                let cell = tableView.dequeueReusableCell(withIdentifier: "AccountCell") as! AccountCell
                cell.configure(account: self.account)
                return cell
            case logoutRow:
                let cell = tableView.dequeueReusableCell(withIdentifier: "LogoutCell") as! LogoutCell
                cell.configure(account: self.account)
                return cell
            default:
                break
            }
            break
        default:
            break
        }
        
        return UITableViewCell()
    }
}
