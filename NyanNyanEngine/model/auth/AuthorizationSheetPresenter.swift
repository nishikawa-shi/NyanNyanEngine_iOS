//
//  AuthorizationSheetPresenter.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2026/09/05.
//  Copyright © 2026 Tetsuya Nishikawa. All rights reserved.
//

import UIKit

//UIViewController をそのまま受け渡さないのは、認可シートの提示元という役割だけを
//渡すため。画面そのものを渡すと、受け取った側が画面の操作一式を握れてしまう
protocol AuthorizationSheetPresenter: AnyObject {
    //presentingViewController という名前を避けているのは、UIViewController が
    //同名で別の意味（自分を提示した側）のプロパティを持っており、
    //意図せず準拠が満たされてしまうため
    var viewControllerForAuthorizationSheet: UIViewController { get }
}
