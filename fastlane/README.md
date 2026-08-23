fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios load_certs

```sh
[bundle exec] fastlane ios load_certs
```

provisioning profile読み取りlane

### ios add_device_to_profiles

```sh
[bundle exec] fastlane ios add_device_to_profiles
```

provisioning profileへの端末追加lane

### ios produce_certs

```sh
[bundle exec] fastlane ios produce_certs
```

provisioning profile生成lane

### ios build_beta_dev

```sh
[bundle exec] fastlane ios build_beta_dev
```

dev環境向けβ版アプリ配布用のad-hoc署名ipaを作るlane

使い方: bundle exec fastlane build_beta_dev build_number:20260823.1

事前に load_certs を実行して証明書とprovisioning profileを取得しておくこと

### ios build_beta

```sh
[bundle exec] fastlane ios build_beta
```

prd環境向けβ版アプリ配布用のad-hoc署名ipaを作るlane

使い方: bundle exec fastlane build_beta build_number:20260822.1

事前に load_certs を実行して証明書とprovisioning profileを取得しておくこと

### ios upload_ipa_to_testflight

```sh
[bundle exec] fastlane ios upload_ipa_to_testflight
```

TestFlight配布用のapp-store署名ipaを作り、App Store Connectへアップロードするlane

使い方: bundle exec fastlane upload_ipa_to_testflight build_number:20260822.1

事前に load_certs を実行して証明書とprovisioning profileを取得しておくこと

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
