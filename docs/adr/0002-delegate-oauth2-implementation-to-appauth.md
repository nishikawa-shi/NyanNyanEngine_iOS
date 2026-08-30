# 2. OAuth 2.0 の実装を AppAuth に委ねる

日付: 2026-08-30

## 状態

採用

## 状況

X API の認証を OAuth 2.0 PKCE へ移行するには、次の要素が要る。

- `code_verifier` と `code_challenge`（S256）の生成
- 認可URLの組み立てと、認可画面の提示
- 認可コードとトークンの交換
- アクセストークンの期限管理とリフレッシュ
- 認証状態の永続化

このうちリフレッシュの扱いが最も危うい。X はリフレッシュトークンをローテーションするため、並行して401を受けた複数のリクエストがそれぞれリフレッシュを試みると、片方が古いトークンで失敗し、利用者がログアウトへ落ちる。これを防ぐには、リフレッシュを直列化して結果を共有する必要がある。この種の競合はユニットテストで再現しにくく、実機でも稀にしか起きない。

当初の計画では、これらをすべて自作する予定だった。

## 決定

OAuth 2.0 のクライアント実装を `AppAuth`（`pod 'AppAuth', '~> 3.0'`）に委ねる。

`AppAuth` は OpenID Foundation が公開しており、この移行が従っている RFC 8252（OAuth 2.0 for Native Apps）のリファレンス実装にあたる。仕様を定めた側による実装である。

X は OIDC ディスカバリに対応しないため、`OIDServiceConfiguration` にはエンドポイントを直接指定して構築する。

委ねる範囲は次のとおり。

| 要素 | 担当 |
| --- | --- |
| PKCE の生成 | `OIDAuthorizationRequest` が内部で行う |
| 認可画面の提示 | `OIDExternalUserAgentIOS` が `ASWebAuthenticationSession` を内包する |
| トークン交換とリフレッシュ | `OIDAuthState` が期限判定と直列化を行う |
| 認証状態の永続化 | 利用側の責務。`KeychainConnector` が担う |

## 却下した選択肢

すべてを自作する案を却下した。動くものは作れるが、リフレッシュの直列化とトークンのローテーションという、事故が起きたときの影響が大きく再現の難しい領域を、実績のない実装で持つことになる。この領域の正しさに払うコストは、依存を1つ増やすコストを上回る。

`AppAuth` 3.0.0 が要求する iOS 15.0 は、このプロジェクトのデプロイメントターゲットと一致するため、追加の引き上げは発生しない。

## 結果

自作を予定していた `PKCEGenerator` / `OAuth2RequestFactory` / `AuthenticationSessionPresenter` の3つは不要になった。`ApiClient` が持つ予定だったリフレッシュ制御も `OIDAuthState` へ移る。

`AppAuth` はコールバックベースのAPIを持つため、RxSwift へのブリッジは利用側で書く。既存のリポジトリ層が `FirebaseClient` に対して同じことをしているため、新しい様式にはならない。

`Pods/` がGit追跡対象のため、導入により `Pods/AppAuth/` の69ファイルがリポジトリへ入る。あわせて `Pods/Pods.xcodeproj/project.pbxproj` が再生成され、約4万行の増減が生じる。これは CocoaPods が `pod install` のたびにUUIDを振り直すためで、内容の変化ではない。

## 戻す条件

Apple が `AuthenticationServices` に OAuth 2.0 の認可コードフローを直接扱うAPIを追加し、リフレッシュの直列化まで含めて提供するようになった場合、依存を外して標準APIへ寄せる余地が生まれる。
