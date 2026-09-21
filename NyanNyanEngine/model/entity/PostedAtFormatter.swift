//
//  PostedAtFormatter.swift
//  NyanNyanEngine
//
//  Created by Tetsuya Nishikawa on 2019/05/06.
//  Copyright © 2019 Tetsuya Nishikawa. All rights reserved.
//

import Foundation

//読む相手ではなく作るものを名乗っているのは、Xの書式が変わってもこの型の
//仕事（投稿時刻を一覧へ出す形にすること）が変わらないため。
//文字列の拡張にせず型として残しているのは、答えが現在時刻にも依るため。
//同じ文字列でも呼ぶ時刻で結果が変わるものを、文字列の性質として名乗らせると嘘になる
class PostedAtFormatter {
    //経過時間の言い回しを自前で組み立てないのは、単位の切り替わりも
    //言語ごとの語順も、OSが各言語ぶんのデータを持っているため。
    //abbreviated を選んでいるのは、他のstyleが日本語で「10 分前」と空白を挟み、
    //一覧の1行に収める見せ方と合わないため
    private let relativeFormatter: RelativeDateTimeFormatter = {
        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .abbreviated
        relativeFormatter.dateTimeStyle = .numeric
        //端末の言語ではなくアプリが実際に表示している言語に合わせるのは、
        //このアプリが日本語と英語しか持たないため。既定のままだと、
        //その2つ以外を使う利用者の画面で、文言は英語なのに時刻だけ
        //母語という食い違いが起きる
        relativeFormatter.locale = Locale(identifier: Bundle.main.preferredLocalizations.first ?? "en")
        return relativeFormatter
    }()

    func getNyanNyanTimeStamp(apiTimeStamp: String) -> String {
        guard let createdAtDate = apiTimeStamp.toPostedAtDate() else { return "秘密" }
        return self.relativeFormatter.localizedString(for: createdAtDate, relativeTo: Date())
    }
}

//変換の主語を文字列の側に置いているのは、読むのに要るものが文字列しか
//無いため。フォーマッタのメソッドにすると、フォーマッタ自身を日付へ
//変換しているように読める。
//秒の小数部が無い形を試さないのは、ISO8601DateFormatterが小数部の有無を
//排他に扱い、両方を読むには解釈を2回重ねることになるため。Xが返す形は
//1つなので、実データで一度も通らない側を抱えることになる。
//読み違えても例外にもログにも出ず、一覧の時刻が全件「秘密」になるだけなので、
//そうなったら画面を見れば分かる
private extension String {
    func toPostedAtDate() -> Date? {
        let postedAtFormatter = ISO8601DateFormatter()
        postedAtFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return postedAtFormatter.date(from: self)
    }
}
