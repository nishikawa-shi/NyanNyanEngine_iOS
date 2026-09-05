platform :ios, '15.0'

target 'NyanNyanEngine' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for NyanNyanEngine
  pod 'Firebase/Analytics',     '~> 12.0'
  pod 'Firebase/Auth',          '~> 12.0'
  pod 'Firebase/Crashlytics',   '~> 12.0'
  pod 'Firebase/Firestore',     '~> 12.0'
  pod 'R.swift',                '~> 7'
  pod 'RxSwift',                '~> 6.9'
  pod 'RxCocoa',                '~> 6.9'
  pod 'RxDataSources',          '~> 5.0'
  pod 'CryptoSwift',            '~> 1.8'
  pod 'AppAuth',                '~> 3.0'
  # Nuke 11以降はSPM専用配布のため、CocoaPods継続の間は10系に留める（SPM移行時に最新化）
  pod 'Nuke',                   '~> 10'

  target 'NyanNyanEngineTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'NyanNyanEngineUITests' do
    inherit! :search_paths
    pod 'Firebase/Analytics',     '~> 12.0'
    pod 'Firebase/Auth',          '~> 12.0'
    pod 'Firebase/Firestore',     '~> 12.0'
    pod 'R.swift',                '~> 7'
    pod 'RxSwift',                '~> 6.9'
    pod 'RxCocoa',                '~> 6.9'
    pod 'RxDataSources',          '~> 5.0'
    pod 'CryptoSwift',            '~> 1.8'
    pod 'AppAuth',                '~> 3.0'
    pod 'Nuke',                   '~> 10'
    # Pods for testing
  end

end

# 旧Podが宣言するiOS 9/10最小要件をXcode 26が拒否するため、全PodターゲットをiOS 15.0以上へ引き上げる
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < 15.0
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      end
    end
  end
end
