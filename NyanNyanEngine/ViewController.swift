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
            .responseString(encoding: .utf8) { [weak self] response in
                
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                guard let body = response.value?.data(using: .utf8) else { return }
                guard let testStatusObj = try? decoder.decode([Status].self, from: body).first else { return }
                
                self?.testLabel.text = testStatusObj.text
        }
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


}

