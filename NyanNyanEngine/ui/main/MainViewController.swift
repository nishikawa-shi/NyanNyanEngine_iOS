//
//  MainViewController.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 9/16/19.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import UIKit

class MainViewController: UITabBarController {
    
    @IBOutlet weak var mainTabBar: UITabBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if(self.isShowingTimelineView() && item.isTimelineItem()) {
            print("nyao---n")
        }
    }
}

private extension UITabBarController {
    func isShowingTimelineView() -> Bool {
        return self.selectedIndex == 0
    }
}

private extension UITabBarItem {
    func isTimelineItem() -> Bool {
        return self.title == "Timeline"
    }
}
