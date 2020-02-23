//
//  HashTagSettingViewController.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2/23/20.
//  Copyright © 2020 Tetsuya Nishikawa. All rights reserved.
//

import UIKit

class HashTagSettingViewController: UIViewController {
    @IBOutlet weak var settingList: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureSettingsList()
    }
    
    private func configureSettingsList() {
        settingList.register(UINib(nibName: "SwitchConfigCell", bundle: nil), forCellReuseIdentifier: "SwitchConfigCell")
        settingList.delegate = self
        settingList.dataSource = self
    }
}

extension HashTagSettingViewController: UITableViewDelegate {
    
}

extension HashTagSettingViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
        
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchConfigCell", for: indexPath) as? SwitchConfigCell else { return UITableViewCell() }
        switch indexPath.row {
        case 0:
            cell.configure(type: .hashtagEngine)
            break
        case 1:
            cell.configure(type: .hashtagNadenade)
            break
        default:
            break
        }
        return cell
    }
}
