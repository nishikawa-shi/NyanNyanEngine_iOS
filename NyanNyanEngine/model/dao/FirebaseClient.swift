//
//  FirebaseConnector.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2/1/20.
//  Copyright © 2020 Tetsuya Nishikawa. All rights reserved.
//

import Foundation
import Firebase
import RxSwift

protocol BaseFirebaseClient: AnyObject {
    func authAnonymously() -> Observable<String>
}

class FirebaseClient: BaseFirebaseClient {
    static let shared = FirebaseClient()
    private init() { }

    func authAnonymously() -> Observable<String>{
        return Observable<String>.create { observer in
            Auth.auth().signInAnonymously { res, err in
                guard let res = res else { return }
                observer.onNext(res.user.uid)
            }
            return Disposables.create()
        }
    }
}
