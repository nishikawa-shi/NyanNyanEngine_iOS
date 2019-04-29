//
//  ViewController.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/04/28.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import UIKit
import Alamofire
import RxSwift

class ViewController: UIViewController {
    private let disposeBag = DisposeBag()
    
    @IBOutlet weak var testLabel: UILabel!
    override func viewDidLoad() {
        getHomeTimeline()
            .map { [unowned self] in self.toResponseBody(dataResponse: $0) }
            .map { [unowned self] in self.toStatuses(data: $0) }
            .map { [unowned self] in self.set1stTitleToTestLabel(sourceStatuses: $0) }
            .subscribe()
            .disposed(by: disposeBag)
        
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    func getHomeTimeline() -> Observable<DataResponse<String>> {
        return Observable<DataResponse<String>>.create { observer in
            Alamofire.request("https://nyannyanengine-ios-d.firebaseapp.com/1.1/statuses/home_timeline.json", method: .get)
                .responseString(encoding: .utf8) { observer.onNext($0) }
            return Disposables.create()
        }
    }

    private func toResponseBody(dataResponse: DataResponse<String>) -> Data? {
        return dataResponse.value?.data(using: .utf8)
    }
    
    private func toStatuses(data: Data?) -> [Status]? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let d = data else { return nil }
        return try? decoder.decode([Status].self, from: d)
    }
    
    private func set1stTitleToTestLabel(sourceStatuses: [Status]?) {
        self.testLabel.text = sourceStatuses?.first?.text
    }
}

