platform :ios, '15.0'

target 'NyanNyanEngine' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for NyanNyanEngine
  pod 'Firebase/Analytics',     '~> 12.0'
  pod 'Firebase/Auth',          '~> 12.0'
  pod 'Firebase/Crashlytics',   '~> 12.0'
  pod 'Firebase/Firestore',     '~> 12.0'
  pod 'R.swift',                '~> 5'
  pod 'RxSwift',                '~> 5'
  pod 'RxCocoa',                '~> 5'
  pod 'RxDataSources',          '~> 4.0'
  pod 'CryptoSwift'
  pod 'Nuke',                   '~> 7.0'

  target 'NyanNyanEngineTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'NyanNyanEngineUITests' do
    inherit! :search_paths
    pod 'Firebase/Analytics',     '~> 12.0'
    pod 'Firebase/Auth',          '~> 12.0'
    pod 'Firebase/Firestore',     '~> 12.0'
    pod 'R.swift',                '~> 5'
    pod 'RxSwift',                '~> 5'
    pod 'RxCocoa',                '~> 5'
    pod 'RxDataSources',          '~> 4.0'
    pod 'CryptoSwift'
    pod 'Nuke',                   '~> 7.0'
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
