# にゃんにゃんエンジン iOS

投稿も、タイムラインも、ぜんぶ猫語になるクライアントアプリ。

## 開発環境

| ツール | バージョン | 固定方法 |
| --- | --- | --- |
| Xcode | 26.2 | `.xcode-version` |
| Ruby | 3.1.2 | `.ruby-version` |
| fastlane | `Gemfile.lock` 参照 | `Gemfile` |
| Firebase CLI | `package-lock.json` 参照 | `package.json`（CIの配布ステージでのみ使用） |

ライブラリは Swift Package Manager で取得する。バージョンは `NyanNyanEngine.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` で固定されており、初回ビルド時に Xcode が解決する。

## ディレクトリ構成

| パス | 内容 |
| --- | --- |
| `NyanNyanEngine/model/` | エンティティ、リポジトリ、DAO、ネットワーク |
| `NyanNyanEngine/ui/` | 画面とビュー |
| `NyanNyanEngine/res/values/strings/` | 文言（ja / en） |
| `NyanNyanEngineTests/` | ユニットテスト |
| `fastlane/` | 証明書管理と配布のレーン |
| `public/` | Firebase Hosting の配信内容 |

## ビルドとテスト

Xcode で開く場合は `NyanNyanEngine.xcodeproj` を使う。

ビルド構成は `Debug` と `Release` の2つで、それぞれが開発環境と本番環境に1対1で対応する。接続先の切り替えは `#if DEBUG` / `#elseif RELEASE` のコンパイル条件で行っており、複数のソースファイルに分散している。ビルド構成を増やすときは、そのすべてに分岐を足すこと。どれか1つでも `#else` に落ちると、ビルドは成功したまま実行時に nil で落ちる。

コマンドラインでユニットテストを実行する場合:

```sh
xcodebuild \
  -project NyanNyanEngine.xcodeproj \
  -scheme NyanNyanEngineTests \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  -testLanguage en -testRegion US \
  -skipPackagePluginValidation \
  test
```

`-skipPackagePluginValidation` の明示は必須。R.swift をビルドツールプラグインとして使っており、コマンドラインからのビルドでは対話的な承認ができないため、これが無いとプラグインの実行前で止まる。

`-sdk` を指定しないこと。プラットフォームは `-destination` が決めるため冗長であるうえ、`-sdk iphonesimulator` はビルドツールプラグインが呼ぶ生成ツール（Macの上で走る実行ファイル）までシミュレータ向けにビルドさせてしまい、プラグインが実行時に落ちる。

`-testLanguage` / `-testRegion` の明示は必須。Xcode 26 ではテスト実行時のロケールがデフォルトで非決定のため、ローカライズ文字列を比較するテストが環境によって落ちる。

同名のシミュレータが複数登録されている場合は `name=` が曖昧になる。`xcrun simctl list devices available` で確認し、`id=<UDID>` で指定すること。

build と test を1回の `xcodebuild` 呼び出しで同時指定しないこと（`build test` のようなアクション併記）。スキーム解決に失敗して「Supported platforms is empty」になる。

## 配布

配布は GitHub Actions から行う。ローカルからの手動配布は想定していない（署名環境の差が事故のもとになるため）。ジョブの構成とトリガは `.github/workflows/ci.yml` を参照。

ビルド番号（`CFBundleVersion`）はCIがビルド時に注入するため、`project.pbxproj` の `CURRENT_PROJECT_VERSION` は書き換えない。バージョン番号（`CFBundleShortVersionString`）は `MARKETING_VERSION` を手で更新する。

## 秘密情報と証明書の取り扱い

Git追跡対象外ファイルの準備方法、および証明書とプロビジョニングプロファイルの管理手順は、別途ドキュメントに定める。

## 注意

Firebase Hosting へデプロイしないこと。`public/` の内容と実際の配信内容が乖離しており、いまデプロイすると配信されていないファイルが配信され始め、リポジトリに存在しないファイルが消える。
