# 1. OAuthのコールバックに逆ドメイン形式のカスタムURLスキームを使う

日付: 2026-08-30

## 状態

採用

## 状況

X API の認証を OAuth 1.0a から OAuth 2.0 PKCE へ移行するにあたり、認可後にアプリへ戻る経路を決める必要がある。

移行前のコードは Universal Link を使っていた。`NyanNyanEngine.entitlements` に `applinks:nyannyanengine.firebaseapp.com` と dev 用の1件を宣言し、Firebase Hosting 上の中継ページから `AppDelegate` の `continue userActivity` で受け取る作りになっている。

一般的なディープリンクの文脈では、カスタムURLスキームは所有権が検証されず、同じスキームを名乗る別アプリに横取りされうるため、Universal Link が推奨されてきた。この認識は正しい。

## 決定

コールバックには逆ドメイン形式のカスタムURLスキームを使う。

| ビルド構成 | コールバックURI |
| --- | --- |
| `Debug` | `com.ntetz.ios.nyannyanengine-d://callback` |
| `Release` | `com.ntetz.ios.nyannyanengine://callback` |

`ASWebAuthenticationSession` でスキームを指定して認可画面を提示し、コールバックはその completion handler で受け取る。

## 却下した選択肢

Universal Link を継続する案を却下した。理由は3つある。

`ASWebAuthenticationSession` で https コールバックを受け取る API（`ASWebAuthenticationSession(url:callback:)`）は iOS 17.4 以降でのみ利用できる。このプロジェクトのデプロイメントターゲットは iOS 15.0 のため、そのままでは使えない。ターゲットを維持したまま Universal Link で受けようとすると `AppDelegate` の `continue userActivity` に戻ることになり、認可セッションの外でコールバックを受け取る構造に逆戻りする。

Universal Link には `apple-app-site-association` の配信が要る。配信元である Firebase Hosting は、リポジトリの `public/` と実際の配信内容が乖離しており、デプロイを禁止する方針を README に記載している。この状態を解消しない限り、宣言と実配信の一致を保証できない。

アプリが未インストールの場合や、`apple-app-site-association` がキャッシュされていない場合、リンクは Safari で開かれる。認証フローの途中でこれが起きると、利用者はブラウザに取り残される。

## 結果

横取りに対する安全性は、次の2つで担保される。

`ASWebAuthenticationSession` はコールバックを呼び出し元アプリの completion handler へ直接渡す。OS の URL オープン機構を経由しないため、同じスキームを登録した別アプリが割り込む余地がない。移行前のコードが使っていた `SFSafariViewController` にはこの保護がなく、外部ブラウザ経由でコールバックが配送されていた。

PKCE により、認可コードを傍受されても `code_verifier` なしにはトークンへ交換できない。RFC 7636 が対策の対象としているのは、まさにモバイルにおけるリダイレクトの傍受である。

この選択は RFC 8252（OAuth 2.0 for Native Apps、BCP 212）の範囲内にある。同文書はリダイレクト先として、逆ドメイン形式のカスタムスキーム、所有権を主張した https URI、ループバックの3つを認めている。

`NyanNyanEngine.entitlements` の `applinks:` 2件は、認証以外に用途がないため削除する。これによりアプリから Universal Link の宣言がなくなる。

## 戻す条件

Universal Link へ移すのが妥当になるのは、次の3つがすべて揃ったとき。

- Firebase Hosting の配信内容とリポジトリの `public/` の乖離が解消されている
- デプロイメントターゲットが iOS 17.4 以降へ上がっている
- 認証以外にもディープリンクで受けたい導線が生まれている
