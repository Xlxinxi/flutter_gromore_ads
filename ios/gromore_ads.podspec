#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint gromore_ads.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'gromore_ads'
  s.version          = '0.0.1'
  s.summary          = '一款优质的 Flutter 广告插件（GroMore、穿山甲）'
  s.description      = <<-DESC
  一款基于穿山甲GroMore SDK的Flutter广告插件，支持开屏、插屏、激励视频、信息流等多种广告形式。完全使用CocoaPods管理依赖，版本7.1.0.3支持完整ADN聚合。
                       DESC
  s.homepage         = 'https://www.zhecent.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'lightcore' => '369620805@qq.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  
  # GroMore 聚合 SDK - 版本 7.1.0.8 （包含 BUAdSDK）
  s.dependency 'Ads-CN/CSJMediation', '6.8.1.3'

  # GroMore 测试 SDK（仅在 Debug 模式下有效）
  s.dependency 'BUAdTestMeasurement', '6.8.1.3', :configurations => ['Debug']
  
  # 引入使用到的ADN SDK，开发者请按需引入
  # s.dependency 'GDTMobSDK', '4.15.41'
  # s.dependency 'BaiduMobAdSDK', '5.394'
  # s.dependency 'KSAdSDK', '4.6.30.1'
  # s.dependency 'SigmobAd-iOS', '4.20.0'
  # s.dependency 'MintegralAdSDK', '7.7.7'
  # s.dependency 'Google-Mobile-Ads-SDK', '10.0.0'
  # s.dependency 'UnityAds', '4.3.0'
  
  s.platform = :ios, '12.0'
  s.static_framework = true

  # 系统框架依赖
  s.frameworks = [
    'UIKit', 
    'MapKit', 
    'WebKit', 
    'MediaPlayer', 
    'CoreLocation', 
    'AdSupport', 
    'CoreMedia', 
    'AVFoundation', 
    'CoreTelephony', 
    'StoreKit',
    'SystemConfiguration', 
    'MobileCoreServices', 
    'CoreMotion', 
    'Accelerate',
    'AudioToolbox',
    'JavaScriptCore',
    'Security',
    'CoreImage',
    'AudioToolbox',
    'ImageIO',
    'QuartzCore',
    'CoreGraphics',
    'CoreText',
    'CoreHaptics',
    'CoreML',
    'AppTrackingTransparency'
  ]
  
  # 系统库依赖  
  s.libraries = [
    'c++', 
    'resolv', 
    'z', 
    'sqlite3', 
    'bz2', 
    'xml2', 
    'iconv', 
    'c++abi'
  ]

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES', 
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'OTHER_LDFLAGS' => '-ObjC'
  }
  s.swift_version = '5.0'

  # Privacy manifest for App Store compliance
  s.resource_bundles = {'gromore_ads_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
