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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        let hashTagSection = 0
        let hashTagRows = [0, 1]
        hashTagRows.forEach { rowNum in
            guard let cell = settingList.cellForRow(at: IndexPath(row: rowNum, section: hashTagSection)) as? SwitchConfigCell,
                let hashTagType = cell.hashTagType else { return }
            LocalSettingsRepository.shared.saveHashtagSetting(type: hashTagType, value: cell.configValue.isOn)
        }
    }
    
    private func configureSettingsList() {
        settingList.register(UINib(nibName: "SwitchConfigCell", bundle: nil), forCellReuseIdentifier: "SwitchConfigCell")
        settingList.delegate = self
        settingList.dataSource = self
    }
}

extension HashTagSettingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let hashTagSection = 0
        if indexPath.section == hashTagSection {
            guard let cell = settingList.cellForRow(at: IndexPath(row: indexPath.row, section: hashTagSection)) as? SwitchConfigCell else { return }
            cell.configValue.setOn(cell.configValue.isOn ? false : true, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
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
