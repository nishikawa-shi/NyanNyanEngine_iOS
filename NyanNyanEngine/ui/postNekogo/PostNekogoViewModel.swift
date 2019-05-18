//
//  PostNekogoViewModel.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/05/18.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

protocol PostNekogoViewModelInput: AnyObject {
    var originalTextChangedTo: AnyObserver<String?>? { get }
}

protocol PostNekogoViewModelOutput: AnyObject {
    var nekogoText: Observable<String?> { get }
}

final class PostNekogoViewModel: PostNekogoViewModelInput, PostNekogoViewModelOutput {
    var originalTextChangedTo: AnyObserver<String?>? = nil
    
    var nekogoText: Observable<String?>
    
    init() {
        let _nekogoText = BehaviorRelay<String?>(value: nil)
        self.nekogoText = _nekogoText.asObservable()
        
        self.originalTextChangedTo = AnyObserver<String?> {
            guard let texiViewValue = $0.element,
                let originalText = texiViewValue else { return }
            _nekogoText.accept(Nekosan().createNekogo(sourceStr: originalText))
        }
    }
}
