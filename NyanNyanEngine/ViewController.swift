//
//  ViewController.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/04/28.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import UIKit
import Alamofire

class ViewController: UIViewController {

    @IBOutlet weak var testLabel: UILabel!
    override func viewDidLoad() {
        Alamofire.request("https://nyannyanengine-ios-d.firebaseapp.com/1.1/statuses/home_timeline.json", method: .get)
            .responseJSON { [weak self] response in
                if let body = response.result.value as? NSArray,
                    let firstElement = body.firstObject as? Dictionary<String, AnyObject> {
                    self?.testLabel.text = (firstElement["text"] as? String) ?? "値が取れなかったよ・・・"
                }
        }
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


}

