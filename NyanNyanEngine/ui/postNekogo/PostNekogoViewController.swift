//
//  PostNekogoViewController.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/05/17.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import UIKit

class PostNekogoViewController: UIViewController {
    
    @IBAction func touchCancelAction(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func touchPostNekogoAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}
