//
//  MainViewController.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 9/16/19.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import UIKit

class MainViewController: UITabBarController {
    private let input: MainViewModelInput
    private let output: MainViewModelOutput
    
    init(viewModel: MainViewModelInput & MainViewModelOutput = MainViewModel()) {
        self.input = viewModel
        self.output = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        let viewModel = MainViewModel()
        self.input = viewModel
        self.output = viewModel
        super.init(coder: aDecoder)
    }
    
    @IBOutlet weak var mainTabBar: UITabBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if(self.isShowingTimelineView() && item.isTimelineItem()) {
            self.input.extraTimelineItemTap?.onNext("0000/01/01 00:00:00")
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
        //storyboardから、タイムライン用UITabBarItemに1という値をハードコーディングしたのでこっちもそれに合わせた
        return self.tag == 1
    }
}
