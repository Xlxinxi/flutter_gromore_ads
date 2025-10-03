# GroMore 广告插件

[![pub package](https://img.shields.io/pub/v/gromore_ads.svg)](https://pub.dev/packages/gromore_ads)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

GroMore 广告插件基于穿山甲（Pangle）GroMore 聚合能力，为 Flutter 应用提供开屏、插屏、横幅、激励、信息流等多种广告形式。

## ✨ 功能亮点

- 🚀 支持开屏、插屏、Banner、激励视频、信息流、Draw Feed
- 🎯 内置事件监听与奖励回调
- 📱 iOS 与 Android 双端统一 API
- 🧱 提供 Banner/Feed Widget，快速落地
- 🔐 提供授权与个性化配置接口

## 🛠️ 环境要求

- **Flutter**: >=3.3.0
- **Dart**: ^3.9.0
- **Android**: minSdkVersion 24
- **iOS**: iOS 10.0+

## 📦 安装

```yaml
dependencies:
  gromore_ads: ^latest_version
```

## 🚀 快速开始

```dart
import 'dart:io';
import 'package:gromore_ads/gromore_ads.dart';

// 初始化SDK并预加载广告
Future<void> _bootstrapAds() async {
  try {
    // 1) 可选隐私权限
    if (Platform.isIOS) {
      await GromoreAds.requestIDFA;
    } else if (Platform.isAndroid) {
      await GromoreAds.requestPermissionIfNecessary;
    }

    // 2) 注册事件监听器
    _adEventSubscription = GromoreAds.onEvent(
      onEvent: (event) {
        debugPrint('📌 广告事件: ${event.action} (posId: ${event.posId})');
      },
      onError: (event) {
        debugPrint('❌ 广告错误 ${event.code}: ${event.message}');
      },
      onReward: (event) {
        if (event.verified) {
          debugPrint('✅ 奖励验证成功: ${event.rewardType ?? ''} x${event.rewardAmount ?? 0}');
        }
      },
    );

    // 3) 初始化 SDK
    final success = await GromoreAds.initAd(
      'your_app_id',
      useMediation: true,
      debugMode: true,
    );

    if (success) {
      // 4) 可选：预加载常用广告位
      await GromoreAds.preload(
        configs: const [
          PreloadConfig.rewardVideo(['reward_pos_id']),
          PreloadConfig.interstitial(['interstitial_pos_id']),
          PreloadConfig.feed(['feed_pos_id']),
          PreloadConfig.banner(['banner_pos_id']),
        ],
      );
    } else {
      debugPrint('SDK初始化失败，请检查配置');
    }
  } catch (e) {
    debugPrint('广告SDK启动异常: $e');
  }
}
```

## 📺 广告类型

### 开屏广告

```dart
await GromoreAds.showSplashAd(
  SplashAdRequest(
    posId: 'splash_pos_id',
    timeout: Duration(seconds: 4),
    logo: SplashAdLogo.asset('assets/logo.png', heightRatio: 0.15),
  ),
);
```

### 插屏广告

```dart
// 先加载
await GromoreAds.loadInterstitialAd('interstitial_pos_id');

// 后展示
await GromoreAds.showInterstitialAd('interstitial_pos_id');
```

### Banner 广告（Widget）

```dart
AdBannerWidget(
  posId: 'banner_pos_id',
  width: 375,
  height: 60,
  onAdLoaded: () => print('Banner加载成功'),
)
```

### 激励视频

```dart
// 加载
await GromoreAds.loadRewardVideoAd('reward_pos_id');

// 展示
await GromoreAds.showRewardVideoAd('reward_pos_id');

// 监听奖励
GromoreAds.onRewardVideoEvents(
  'reward_pos_id',
  onRewarded: (event) {
    if (event.verified) {
      print('🎁 获得奖励: ${event.rewardAmount}');
    }
  },
);
```

### 信息流广告

```dart
// 加载广告（返回广告ID列表）
final adIds = await GromoreAds.loadFeedAd(
  'feed_pos_id',
  width: 375,
  height: 300,
  count: 3,
);

// 在列表中渲染
AdFeedWidget(
  posId: 'feed_pos_id',
  adId: adIds[0],
  width: 375,
  height: 300,
)
```

### Draw 信息流

```dart
// 加载
final drawIds = await GromoreAds.loadDrawFeedAd(
  'draw_pos_id',
  width: 375,
  height: 300,
  count: 3,
);

// 渲染
AdDrawFeedWidget(
  posId: 'draw_pos_id',
  adId: drawIds[0],
  width: 375,
  height: 300,
)
```

## 📊 事件监听

### 全局监听

```dart
_subscription = GromoreAds.onEvent(
  onEvent: (event) => print('事件: ${event.action}'),
  onError: (event) => print('错误: ${event.message}'),
  onReward: (event) => print('奖励: ${event.rewardAmount}'),
  onEcpm: (event) => print('eCPM: ${event.ecpm}'),
);
```

### 按广告位监听

```dart
_subscription = GromoreAds.onAdEvents(
  'your_pos_id',
  onEvent: (event) => print('事件: ${event.action}'),
);
```

### 按类型监听

```dart
// 激励视频
GromoreAds.onRewardVideoEvents('pos_id',
  onLoaded: (e) => print('加载成功'),
  onRewarded: (e) => print('奖励发放'),
);

// 开屏广告
GromoreAds.onSplashEvents('pos_id',
  onClosed: (e) => print('广告关闭'),
);

// 插屏广告
GromoreAds.onInterstitialEvents('pos_id',
  onClosed: (e) => print('广告关闭'),
);
```

**记得取消订阅**：

```dart
@override
void dispose() {
  _subscription?.cancel();
  super.dispose();
}
```

## ⚡ 预加载

```dart
await GromoreAds.preload(
  configs: [
    PreloadConfig.rewardVideo(['reward_id_1', 'reward_id_2']),
    PreloadConfig.interstitial(['interstitial_id']),
    PreloadConfig.feed(['feed_id'], count: 3),
    PreloadConfig.drawFeed(['draw_id'], count: 3),
    PreloadConfig.banner(['banner_id']),
  ],
  maxConcurrent: 3,        // 最大并发数
  intervalMillis: 500,     // 请求间隔(毫秒)
);
```

## 🧪 测试工具

```dart
// 启动GroMore官方测试工具（仅测试环境）
await GromoreAds.launchTestTools();
```

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件。

## 🔗 支持与联系

- 作者：Xlxinxi
- 邮箱：369620805@qq.com
- 微信：light_core
- 📖 [完整文档](https://www.zhecent.com/sdks/flutter-gromore-ads)
- 🐛 [Issue 反馈](https://github.com/Xlxinxi/flutter_gromore_ads/issues)
