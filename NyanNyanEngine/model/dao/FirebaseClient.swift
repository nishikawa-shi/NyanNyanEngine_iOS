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
    func createData(dbName: String, key: String, data: [String: Any])
    func readDatabase(dbName: String,
                      key: String,
                      completionHandler: @escaping ((DocumentSnapshot?, Error?)->Void)) -> Observable<[String: Any]?>
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
    
    func createData(dbName: String, key: String, data: [String: Any]) {
        let db = Firestore.firestore()
        db.collection(dbName).document(key).setData(data)
    }
    
    func readDatabase(dbName: String,
                      key: String,
                      completionHandler: @escaping ((DocumentSnapshot?, Error?)->Void)) -> Observable<[String: Any]?>{
        let db = Firestore.firestore()
        return Observable<[String: Any]?>.create { observer in
            db.collection(dbName).document(key).getDocument { document, error in
                completionHandler(document, error)
                observer.onNext(document?.data())
            }
            return Disposables.create()
        }
    }
}
