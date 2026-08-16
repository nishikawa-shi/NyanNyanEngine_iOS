//
//  UIImageView+Nekosan.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2026/08/16.
//  Copyright © 2026 Tetsuya Nishikawa. All rights reserved.
//

import UIKit
import Nuke

extension UIImageView {
    //ネットワークが繋がらない時に出す絵をネットワーク越しに取りに行かないよう、バンドル同梱のネコさんへフォールバックする
    func setNekosanImage(urlString: String?) {
        guard let urlString = urlString,
            let url = URL(string: urlString) else {
                //URLを持たないのはにゃんにゃ先生などアプリ内のネコさんなので、先生のお顔を出す
                self.image = R.image.nyanNyaSenseiIcon()
                return
        }
        //URLはあるが取得できない場合はどなたか分からないので、名無しのネコさんを出す
        let unknownUserImage = R.image.defaultUser()
        Nuke.loadImage(with: url,
                       options: ImageLoadingOptions(placeholder: unknownUserImage,
                                                    failureImage: unknownUserImage),
                       into: self)
    }
}
