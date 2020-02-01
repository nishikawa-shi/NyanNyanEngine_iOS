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
    func readDatabase(dbName: String, key: String) -> Observable<[String: Any]?>
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
    
    func readDatabase(dbName: String, key: String) -> Observable<[String: Any]?>{
        let db = Firestore.firestore()
        return Observable<[String: Any]?>.create { observer in
            db.collection(dbName).document(key).getDocument { document, error in
                observer.onNext(document?.data())
            }
            return Disposables.create()
        }
    }
}
