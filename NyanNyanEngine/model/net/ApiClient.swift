//
//  HttpClient.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/05/01.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation
import RxSwift

enum ApiError: Error, Equatable {
    case unauthorized
    case forbidden
    case rateLimited
    case serverError
    case unexpectedStatus(Int)
    case noResponse
}

extension ApiError {
    //ステータスコードの解釈をここへ集約しているのは、呼び出し側が
    //数値を持ち回ると、分類の基準が呼び出しの数だけ増えるため
    init(statusCode: Int) {
        switch statusCode {
        case 401:
            self = .unauthorized
        case 403:
            self = .forbidden
        case 429:
            self = .rateLimited
        case 500..<600:
            self = .serverError
        default:
            self = .unexpectedStatus(statusCode)
        }
    }
}

protocol BaseApiClient: AnyObject {
    func executeHttpRequest(urlRequest: URLRequest) -> Observable<Data?>
    func execute(urlRequest: URLRequest) -> Observable<Result<Data, ApiError>>
}

class ApiClient: BaseApiClient {
    static let shared = ApiClient()

    private let urlSession: URLSession

    //private init にしていないのは、テストが URLProtocol のスタブを挿した
    //URLSession を差し替えるため
    init(urlSession: URLSession = URLSession(configuration: .default)) {
        self.urlSession = urlSession
    }

    //応答本文だけを渡す経路。失敗と「本文の無い成功」を区別できないため、
    //新しく足す呼び出しには execute を使う
    func executeHttpRequest(urlRequest: URLRequest) -> Observable<Data?> {
        return self.execute(urlRequest: urlRequest)
            .map { try? $0.get() }
    }

    func execute(urlRequest: URLRequest) -> Observable<Result<Data, ApiError>> {
        //クロージャの中で self.urlSession と書かず先に取り出しているのは、
        //購読が生きている間ずっと自分自身を掴むのを避けるため
        let urlSession = self.urlSession
        let response = Observable<Result<Data, ApiError>>.create { observer in
            let task = urlSession.dataTask(with: urlRequest) { data, response, _ in
                observer.onNext(ApiClient.toResult(data: data, response: response))
                observer.onCompleted()
            }
            task.resume()
            return Disposables.create { task.cancel() }
        }
        //購読側がスケジューラを指定しなくても画面へバインドできるよう、
        //ここでメインスレッドへ寄せている。URLSession のスレッドのまま
        //流すと、UIKit を別スレッドから触ることになる
        return response.observe(on: MainScheduler.instance)
    }

    private static func toResult(data: Data?, response: URLResponse?) -> Result<Data, ApiError> {
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode else { return .failure(.noResponse) }
        //成功を 200 ちょうどに限らないのは、POST /2/tweets が 201 を返すため
        guard (200..<300).contains(statusCode) else { return .failure(ApiError(statusCode: statusCode)) }
        return .success(data ?? Data())
    }
}
