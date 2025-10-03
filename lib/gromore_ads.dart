import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'gromore_ads_platform_interface.dart';

import 'event/ad_event_handler.dart';
import 'splash/splash_ad_request.dart';

export 'event/ad_ecpm_event.dart';
export 'event/ad_error_event.dart';
export 'event/ad_event.dart';
export 'event/ad_event_action.dart';
export 'event/ad_event_handler.dart';
export 'event/ad_reward_event.dart';
export 'splash/splash_ad_request.dart';
export 'view/ad_banner_widget.dart';
export 'view/ad_draw_feed_widget.dart';
export 'view/ad_feed_widget.dart';

/// 方向常量
const int vertical = 1;
const int horizontal = 2;

/// GroMore 广告插件 Dart 封装
class GromoreAds {
  GromoreAds._();

  static GromoreAdsPlatform get _platform => GromoreAdsPlatform.instance;

  // 全局事件流订阅（单例）
  static StreamSubscription<Map<String, dynamic>>? _globalSubscription;

  // 所有活跃的订阅
  static final Set<_AdEventSubscriptionImpl> _activeSubscriptions = {};

  // 确保全局订阅已初始化
  static void _ensureGlobalSubscription() {
    if (_globalSubscription != null) return;

    _globalSubscription = _platform.adEventStream.listen(
      (Map<String, dynamic> payload) {
        try {
          // 分发事件到所有活跃订阅
          for (final subscription in _activeSubscriptions.toList()) {
            if (subscription.isActive) {
              subscription._handleEvent(payload);
            }
          }
        } catch (error, stackTrace) {
          debugPrint('gromore_ads: failed to handle ad event: $error');
          if (kDebugMode) {
            debugPrintStack(stackTrace: stackTrace);
          }
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('gromore_ads: event stream error: $error');
        if (kDebugMode) {
          debugPrintStack(stackTrace: stackTrace);
        }
      },
    );
  }

  /// 监听所有广告事件（全局监听）
  ///
  /// 返回订阅对象，可以通过调用 [AdEventSubscription.cancel] 取消监听。
  ///
  /// **使用示例**:
  /// ```dart
  /// final subscription = GromoreAds.onEvent(
  ///   onEvent: (event) => print('事件: ${event.action}'),
  ///   onError: (error) => print('错误: ${error.message}'),
  /// );
  ///
  /// // 取消监听
  /// subscription.cancel();
  /// ```
  static AdEventSubscription onEvent({
    void Function(AdEvent)? onEvent,
    void Function(AdErrorEvent)? onError,
    void Function(AdRewardEvent)? onReward,
    void Function(AdEcpmEvent)? onEcpm,
  }) {
    _ensureGlobalSubscription();

    final subscription = _AdEventSubscriptionImpl(
      onEvent: onEvent,
      onError: onError,
      onReward: onReward,
      onEcpm: onEcpm,
    );

    _activeSubscriptions.add(subscription);
    return subscription;
  }

  /// 监听指定广告位的事件（自动过滤posId）
  ///
  /// 只接收匹配指定 [posId] 的事件，自动过滤其他广告位的事件。
  ///
  /// **使用示例**:
  /// ```dart
  /// final subscription = GromoreAds.onAdEvents(
  ///   'your_ad_id',
  ///   onEvent: (event) => print('广告事件: ${event.action}'),
  ///   onError: (error) => print('错误: ${error.message}'),
  /// );
  /// ```
  static AdEventSubscription onAdEvents(
    String posId, {
    void Function(AdEvent)? onEvent,
    void Function(AdErrorEvent)? onError,
    void Function(AdRewardEvent)? onReward,
    void Function(AdEcpmEvent)? onEcpm,
  }) {
    _ensureGlobalSubscription();

    final subscription = _AdEventSubscriptionImpl(
      posIdFilter: posId,
      onEvent: onEvent,
      onError: onError,
      onReward: onReward,
      onEcpm: onEcpm,
    );

    _activeSubscriptions.add(subscription);
    return subscription;
  }

  /// 监听激励视频广告事件（便捷方法）
  ///
  /// 只接收指定广告位的激励视频相关事件，并提供细粒度的回调。
  ///
  /// **使用示例**:
  /// ```dart
  /// final subscription = GromoreAds.onRewardVideoEvents(
  ///   'reward_ad_id',
  ///   onLoaded: (_) => print('加载成功'),
  ///   onRewarded: (reward) => print('获得奖励: ${reward.amount}'),
  ///   onError: (error) => print('错误: ${error.message}'),
  /// );
  /// ```
  static AdEventSubscription onRewardVideoEvents(
    String posId, {
    void Function(AdEvent)? onLoaded,
    void Function(AdEvent)? onShowed,
    void Function(AdRewardEvent)? onRewarded,
    void Function(AdEvent)? onCompleted,
    void Function(AdEvent)? onSkipped,
    void Function(AdEvent)? onClicked,
    void Function(AdEvent)? onClosed,
    void Function(AdErrorEvent)? onError,
  }) {
    _ensureGlobalSubscription();

    final subscription = _RewardVideoSubscriptionImpl(
      posId: posId,
      onLoaded: onLoaded,
      onShowed: onShowed,
      onRewarded: onRewarded,
      onCompleted: onCompleted,
      onSkipped: onSkipped,
      onClicked: onClicked,
      onClosed: onClosed,
      onError: onError,
    );

    _activeSubscriptions.add(subscription);
    return subscription;
  }

  /// 监听开屏广告事件（便捷方法）
  static AdEventSubscription onSplashEvents(
    String posId, {
    void Function(AdEvent)? onLoaded,
    void Function(AdEvent)? onShowed,
    void Function(AdEvent)? onClicked,
    void Function(AdEvent)? onClosed,
    void Function(AdErrorEvent)? onError,
  }) {
    _ensureGlobalSubscription();

    final subscription = _SplashSubscriptionImpl(
      posId: posId,
      onLoaded: onLoaded,
      onShowed: onShowed,
      onClicked: onClicked,
      onClosed: onClosed,
      onError: onError,
    );

    _activeSubscriptions.add(subscription);
    return subscription;
  }

  /// 监听插屏广告事件（便捷方法）
  static AdEventSubscription onInterstitialEvents(
    String posId, {
    void Function(AdEvent)? onLoaded,
    void Function(AdEvent)? onShowed,
    void Function(AdEvent)? onClicked,
    void Function(AdEvent)? onClosed,
    void Function(AdErrorEvent)? onError,
  }) {
    _ensureGlobalSubscription();

    final subscription = _InterstitialSubscriptionImpl(
      posId: posId,
      onLoaded: onLoaded,
      onShowed: onShowed,
      onClicked: onClicked,
      onClosed: onClosed,
      onError: onError,
    );

    _activeSubscriptions.add(subscription);
    return subscription;
  }

  /// 监听信息流广告事件（便捷方法）
  static AdEventSubscription onFeedEvents(
    String posId, {
    void Function(AdEvent)? onLoaded,
    void Function(AdEvent)? onShowed,
    void Function(AdEvent)? onClicked,
    void Function(AdEvent)? onClosed,
    void Function(AdErrorEvent)? onError,
  }) {
    _ensureGlobalSubscription();

    final subscription = _FeedSubscriptionImpl(
      posId: posId,
      onLoaded: onLoaded,
      onShowed: onShowed,
      onClicked: onClicked,
      onClosed: onClosed,
      onError: onError,
    );

    _activeSubscriptions.add(subscription);
    return subscription;
  }

  /// 监听Draw信息流广告事件（便捷方法）
  static AdEventSubscription onDrawFeedEvents(
    String posId, {
    void Function(AdEvent)? onLoaded,
    void Function(AdEvent)? onShowed,
    void Function(AdEvent)? onClicked,
    void Function(AdEvent)? onClosed,
    void Function(AdErrorEvent)? onError,
  }) {
    _ensureGlobalSubscription();

    final subscription = _DrawFeedSubscriptionImpl(
      posId: posId,
      onLoaded: onLoaded,
      onShowed: onShowed,
      onClicked: onClicked,
      onClosed: onClosed,
      onError: onError,
    );

    _activeSubscriptions.add(subscription);
    return subscription;
  }

  /// 请求应用跟踪透明度授权(仅 iOS)
  static Future<bool> get requestIDFA async {
    if (!Platform.isIOS) {
      return true;
    }
    return _platform.requestIdfa();
  }

  /// 动态请求相关权限（仅 Android）
  static Future<bool> get requestPermissionIfNecessary async {
    if (!Platform.isAndroid) {
      return true;
    }
    return _platform.requestPermissionIfNecessary();
  }

  /// 初始化GroMore广告
  ///
  /// [config] 支持以下几种形式：
  /// * `String`：可以是 Flutter 资源路径、绝对路径，或直接传入 JSON 字符串
  /// * `Map<String, dynamic>`：会在原生侧自动序列化为 JSON
  ///
  /// 当需要开启聚合初始化加速时，可传入平台导出的本地配置 JSON。
  ///
  /// **平台特定参数**：
  /// * [supportMultiProcess]: 仅Android支持，iOS会自动忽略此参数
  static Future<bool> initAd(
    String appId, {
    required bool useMediation,
    required bool debugMode,
    Object? config,
    int? limitPersonalAds,
    int? limitProgrammaticAds,
    int? themeStatus,
    int? ageGroup,
    bool? supportMultiProcess,  // @android 多进程支持（仅Android）
  }) {
    final params = _buildParams({
      'appId': appId,
      'useMediation': useMediation,
      'debugMode': debugMode,
      'config': config,
      'limitPersonalAds': limitPersonalAds,
      'limitProgrammaticAds': limitProgrammaticAds,
      'themeStatus': themeStatus,
      'ageGroup': ageGroup,
      'supportMultiProcess': supportMultiProcess,
    });
    return _platform.initAd(params);
  }

  /// 广告预缓存入口，入参需使用 [PreloadConfig] 描述待预加载的广告集合。
  static Future<bool> preload({
    required List<PreloadConfig> configs,
    int? parallelNum,
    int? requestIntervalS,
  }) {
    if (configs.isEmpty) {
      throw ArgumentError('configs cannot be empty when calling preload');
    }

    final params = _buildParams({
      'preloadConfigs': configs.map((config) => config.toMap()).toList(),
      'parallelNum': parallelNum,
      'requestIntervalS': requestIntervalS,
    });
    return _platform.preload(params);
  }

  /// 加载并展示开屏广告
  static Future<bool> showSplashAd(SplashAdRequest request) {
    final params = request.toJson();
    return _platform.showSplashAd(params);
  }

  /// 加载插屏广告
  ///
  /// 插屏广告采用"先加载后展示"模式，需先调用此方法加载广告，
  /// 加载成功后再调用 [showInterstitialAd] 展示。
  ///
  /// **参数说明**：
  /// * [posId]: 广告位ID（必填）
  /// * [orientation]: 方向（vertical=1, horizontal=2）
  /// * [mutedIfCan]: 聚合SDK静音开关
  /// * [volume]: 音量（0.0~1.0）**@android 仅Android支持**
  /// * [bidNotify]: 是否回传竞价结果
  /// * [scenarioId]: 自定义场景ID
  /// * [useSurfaceView]: 是否使用SurfaceView播放 **@android 仅Android支持**
  /// * [showDirection]: 聚合额外方向配置 **@ios 仅iOS支持**
  /// * [rewardName]: 奖励名称 **@ios 仅iOS支持（GDT渠道专用）**
  /// * [rewardAmount]: 奖励数量 **@ios 仅iOS支持（GDT渠道专用）**
  /// * [customData]: 透传到原生的自定义数据（用于奖励校验）
  /// * [extraData]: Android渠道扩展字段
  /// * [extraParams]: iOS渠道扩展字段
  ///
  /// **平台特定参数**：
  /// * Android专属：`volume`、`useSurfaceView`
  /// * iOS专属：`showDirection`、`rewardName`、`rewardAmount`
  ///
  /// **使用示例**：
  /// ```dart
  /// // 基本用法
  /// final success = await GromoreAds.loadInterstitialAd('your_pos_id');
  ///
  /// // 完整配置
  /// final success = await GromoreAds.loadInterstitialAd(
  ///   'your_pos_id',
  ///   orientation: vertical,
  ///   mutedIfCan: true,
  ///   volume: 0.5,  // @android
  /// );
  /// ```
  static Future<bool> loadInterstitialAd(
    String posId, {
    int? orientation,
    bool? mutedIfCan,
    double? volume,  // @android 仅Android支持
    bool? bidNotify,
    String? scenarioId,
    bool? useSurfaceView,  // @android 仅Android支持
    int? showDirection,  // @ios 仅iOS支持
    String? rewardName,  // @ios 仅iOS支持（GDT渠道专用）
    int? rewardAmount,  // @ios 仅iOS支持（GDT渠道专用）
    String? customData,
    Map<String, dynamic>? extraData,
    Map<String, dynamic>? extraParams,
  }) {
    final params = _buildParams({
      'posId': posId,
      'orientation': orientation,
      'mutedIfCan': mutedIfCan,
      'volume': volume,
      'bidNotify': bidNotify,
      'scenarioId': scenarioId,
      'useSurfaceView': useSurfaceView,
      'showDirection': showDirection,
      'rewardName': rewardName,
      'rewardAmount': rewardAmount,
      'customData': customData,
      'extraData': extraData,
      'extraParams': extraParams,
    });
    return _platform.loadInterstitialAd(params);
  }

  /// 展示插屏广告
  static Future<bool> showInterstitialAd(String posId) {
    return _platform.showInterstitialAd(posId);
  }

  /// 加载激励视频广告
  static Future<bool> loadRewardVideoAd(
    String posId, {
    int? orientation,
    Object? customData,
    String? userId,
    String? rewardName,
    int? rewardAmount,
    bool? mutedIfCan,
    double? volume,
    bool? bidNotify,
    String? scenarioId,
    bool? useSurfaceView,
    bool? enablePlayAgain,
  }) {
    final params = _buildParams({
      'posId': posId,
      'orientation': orientation,
      'customData': _encodeCustomData(customData),
      'userId': userId,
      'rewardName': rewardName,
      'rewardAmount': rewardAmount,
      'mutedIfCan': mutedIfCan,
      'volume': volume == null ? null : volume.clamp(0.0, 1.0).toDouble(),
      'bidNotify': bidNotify,
      'scenarioId': scenarioId,
      'useSurfaceView': useSurfaceView,
      'enablePlayAgain': enablePlayAgain,
    });
    return _platform.loadRewardVideoAd(params);
  }

  /// 展示激励视频广告
  static Future<bool> showRewardVideoAd(String posId) {
    return _platform.showRewardVideoAd(posId);
  }

  /// 加载信息流广告列表
  ///
  /// 信息流广告采用"批量加载+缓存ID"模式，需先调用此方法加载广告，
  /// 返回的广告ID列表用于后续 [AdFeedWidget] 渲染展示。
  ///
  /// **参数说明**：
  /// * [posId]: 广告位ID（必填）
  /// * [width]: 广告宽度（像素）
  /// * [height]: 广告高度（像素）
  /// * [count]: 请求广告数量（1-3个）
  /// * [mutedIfCan]: 聚合SDK静音开关
  /// * [volume]: 音量（0.0~1.0）**@android 仅Android支持**
  /// * [bidNotify]: 是否回传竞价结果
  /// * [scenarioId]: 自定义场景ID
  /// * [useSurfaceView]: 是否使用SurfaceView播放 **@android 仅Android支持**
  /// * [extra]: Android渠道扩展字段 **@android 仅Android支持**
  ///
  /// **平台特定参数**：
  /// * Android专属：`volume`、`useSurfaceView`、`extra`
  /// * iOS：不支持上述Android专属参数
  ///
  /// **功能限制**：
  /// * 当前仅支持模板模式，不支持自渲染模式
  /// * 返回的广告ID用于 [AdFeedWidget]，每个ID只能使用一次
  ///
  /// **使用示例**：
  /// ```dart
  /// // 基本用法
  /// final adIds = await GromoreAds.loadFeedAd(
  ///   'your_pos_id',
  ///   width: 375,
  ///   height: 300,
  ///   count: 3,
  /// );
  ///
  /// // 完整配置
  /// final adIds = await GromoreAds.loadFeedAd(
  ///   'your_pos_id',
  ///   width: 375,
  ///   height: 300,
  ///   count: 2,
  ///   mutedIfCan: true,
  ///   volume: 0.5,  // @android
  ///   useSurfaceView: true,  // @android
  /// );
  /// ```
  ///
  /// @returns 返回广告ID列表，用于 [AdFeedWidget] 渲染
  ///
  /// @see [clearFeedAd] 清除信息流广告
  /// @see [AdFeedWidget] 信息流广告展示组件
  static Future<List<int>> loadFeedAd(
    String posId, {
    int? width,
    int? height,
    int? count,
    bool? mutedIfCan,
    double? volume,  // @android 仅Android支持
    bool? bidNotify,
    String? scenarioId,
    bool? useSurfaceView,  // @android 仅Android支持
    Map<String, dynamic>? extra,  // @android 仅Android支持
  }) {
    final params = _buildParams({
      'posId': posId,
      'width': width,
      'height': height,
      'count': count,
      'mutedIfCan': mutedIfCan,
      'volume': volume,
      'bidNotify': bidNotify,
      'scenarioId': scenarioId,
      'useSurfaceView': useSurfaceView,
      'extra': extra,
    });
    return _platform.loadFeedAd(params);
  }

  /// 清除信息流广告
  static Future<bool> clearFeedAd(List<int> ids) {
    return _platform.clearFeedAd(ids);
  }

  /// 加载Draw信息流广告列表
  ///
  /// Draw信息流广告是一种特殊的信息流广告类型，支持视频暂停控制、自定义渲染等高级功能。
  /// 采用"批量加载+缓存ID"模式，需先调用此方法加载广告，返回的广告ID列表用于后续 [AdDrawFeedWidget] 渲染展示。
  ///
  /// **参数说明**：
  /// * [posId]: 广告位ID（必填）
  /// * [width]: 广告宽度（像素）
  /// * [height]: 广告高度（像素）
  /// * [count]: 请求广告数量（1-3个）
  /// * [mutedIfCan]: 聚合SDK静音开关
  /// * [volume]: 音量（0.0~1.0） **@android 仅Android支持**
  /// * [bidNotify]: 是否回传竞价结果
  /// * [scenarioId]: 自定义场景ID
  /// * [useSurfaceView]: 是否使用SurfaceView播放 **@android 仅Android支持**
  /// * [extra]: Android渠道扩展字段 **@android 仅Android支持**
  ///
  /// **平台特定参数**：
  /// * Android专属：`volume`、`useSurfaceView`、`extra`
  /// * iOS：不支持上述Android专属参数
  ///
  /// **功能限制**：
  /// * 当前仅支持模板模式，不支持自渲染模式
  /// * 返回的广告ID用于 [AdDrawFeedWidget]，每个ID只能使用一次
  ///
  /// **使用示例**：
  /// ```dart
  /// // 基本用法
  /// final adIds = await GromoreAds.loadDrawFeedAd(
  ///   'your_draw_feed_ad_id',
  ///   width: 375,
  ///   height: 300,
  ///   count: 3,
  /// );
  ///
  /// // 完整配置
  /// final adIds = await GromoreAds.loadDrawFeedAd(
  ///   'your_draw_feed_ad_id',
  ///   width: 375,
  ///   height: 300,
  ///   count: 2,
  ///   mutedIfCan: false,
  ///   volume: 0.8,
  ///   useSurfaceView: true,  // @android
  /// );
  /// ```
  ///
  /// @returns 返回广告ID列表，用于 [AdDrawFeedWidget] 渲染
  ///
  /// @see [clearDrawFeedAd] 清除Draw信息流广告
  /// @see [AdDrawFeedWidget] Draw信息流广告展示组件
  static Future<List<int>> loadDrawFeedAd(
    String posId, {
    int? width,
    int? height,
    int? count,
    bool? mutedIfCan,
    double? volume,
    bool? bidNotify,
    String? scenarioId,
    bool? useSurfaceView,  // @android 仅Android支持
    Map<String, dynamic>? extra,  // @android 仅Android支持
  }) {
    final params = _buildParams({
      'posId': posId,
      'width': width,
      'height': height,
      'count': count,
      'mutedIfCan': mutedIfCan,
      'volume': volume,
      'bidNotify': bidNotify,
      'scenarioId': scenarioId,
      'useSurfaceView': useSurfaceView,
      'extra': extra,
    });
    return _platform.loadDrawFeedAd(params);
  }

  /// 清除Draw信息流广告
  static Future<bool> clearDrawFeedAd(List<int> ids) {
    return _platform.clearDrawFeedAd(ids);
  }

  /// 加载Banner广告
  static Future<bool> loadBannerAd(
    String posId, {
    int? width,
    int? height,
    bool? mutedIfCan,
    double? volume,
    bool? bidNotify,
    String? scenarioId,
    bool? useSurfaceView,
    bool? enableMixedMode,
    Map<String, dynamic>? extraParams,
  }) {
    final params = _buildParams({
      'posId': posId,
      'width': width,
      'height': height,
      'mutedIfCan': mutedIfCan,
      'volume': volume,
      'bidNotify': bidNotify,
      'scenarioId': scenarioId,
      'useSurfaceView': useSurfaceView,
      'enableMixedMode': enableMixedMode,
      'extraParams': extraParams,
    });
    return _platform.loadBannerAd(params);
  }

  /// 展示Banner广告（仅API模式）
  static Future<bool> showBannerAd() {
    return _platform.showBannerAd();
  }

  /// 销毁Banner广告
  static Future<bool> destroyBannerAd() {
    return _platform.destroyBannerAd();
  }

  /// 启动GroMore测试工具
  ///
  /// 打开可视化测试工具界面,用于校验SDK接入、测试广告配置、验证各ADN广告加载是否正常。
  ///
  /// **重要提示**:
  /// - 🔴 此工具**仅用于开发和测试阶段**,上线前**必须移除**相关代码和依赖
  /// - 📋 需要在SDK初始化(`initAd`)完成后调用
  /// - 🧪 使用前需要在穿山甲平台注册测试设备ID
  ///
  /// **平台特定说明**:
  /// - **iOS**:
  ///   - 仅在Debug构建中可用(`#if DEBUG`),Release构建自动禁用
  ///   - 要求iOS 10.0或更高版本
  ///   - 需要引入`BUAdTestMeasurement.xcframework`框架
  /// - **Android**:
  ///   - 需要引入`tools-release.aar`依赖
  ///   - 无构建类型限制,需手动控制调用
  ///
  /// **测试工具功能**:
  /// - ✅ SDK接入检测(融合SDK、各ADN SDK、Adapter版本)
  /// - ✅ 广告位和代码位测试(加载、展示、回调信息)
  /// - ✅ 调试信息查看(错误码、错误信息、CPM等)
  ///
  /// **支持的广告类型**:
  /// - 开屏广告、激励视频广告、信息流广告、Draw信息流、Banner广告
  /// - 注意:插屏广告暂不支持(官方SDK限制)
  ///
  /// **使用示例**:
  /// ```dart
  /// import 'package:flutter/foundation.dart';
  ///
  /// // 推荐:仅在Debug模式使用
  /// if (kDebugMode) {
  ///   try {
  ///     bool success = await GromoreAds.launchTestTools();
  ///     if (success) {
  ///       print('测试工具启动成功');
  ///     }
  ///   } catch (e) {
  ///     print('测试工具启动失败: $e');
  ///   }
  /// }
  /// ```
  ///
  /// **常见错误**:
  /// - `SDK_NOT_READY`: SDK未初始化,请先调用`initAd`
  /// - `ACTIVITY_ERROR`: 无法获取Activity/ViewController
  /// - `DEBUG_ONLY`: iOS Release构建不支持测试工具
  ///
  /// @returns 启动成功返回`true`,失败返回`false`或抛出异常
  ///
  /// @throws 当SDK未初始化、缺少依赖或平台不支持时抛出异常
  ///
  /// @see [initAd] SDK初始化方法
  static Future<bool> launchTestTools() {
    return _platform.launchTestTools();
  }

  /// 获取平台版本（测试用）
  static Future<String?> get getPlatformVersion async {
    return _platform.getPlatformVersion();
  }

  static Map<String, dynamic> _buildParams(Map<String, dynamic?> source) {
    final result = <String, dynamic>{};
    source.forEach((key, value) {
      if (value == null) {
        return;
      }
      if (value is Iterable && value.isEmpty) {
        return;
      }
      if (value is Map && value.isEmpty) {
        return;
      }
      result[key] = value;
    });
    return result;
  }

  static Object? _encodeCustomData(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is String) {
      return value;
    }

    if (value is Map) {
      try {
        return jsonEncode(value);
      } catch (error) {
        if (kDebugMode) {
          debugPrint('customData 序列化失败: $error');
        }
      }
    }

    return value.toString();
  }
}

/// 预加载配置
///
/// [options] 用于透传原生 SDK 所需的额外参数，例如：
/// - 激励/插屏：`orientation`、`userId`、`customData`、`mutedIfCan` 等；
/// - 信息流/Draw/Banner：`width`、`height`、`count`、`mutedIfCan` 等。
/// 具体支持项可参考插件文档说明。
class PreloadConfig {
  static const String rewardVideoType = 'reward_video';
  static const String feedType = 'feed';
  static const String drawFeedType = 'draw_feed';
  static const String interstitialType = 'interstitial';
  static const String bannerType = 'banner';

  /// 广告类型（原生SDK约定的字符串）
  final String adType;

  /// 广告位ID列表
  final List<String> adIds;

  /// 透传给原生预加载的高级参数（可选）
  final Map<String, dynamic>? options;

  const PreloadConfig({
    required this.adType,
    required this.adIds,
    this.options,
  });

  const PreloadConfig.rewardVideo(
    List<String> adIds, {
    Map<String, dynamic>? options,
  }) : this(adType: rewardVideoType, adIds: adIds, options: options);

  const PreloadConfig.feed(List<String> adIds, {Map<String, dynamic>? options})
    : this(adType: feedType, adIds: adIds, options: options);

  const PreloadConfig.drawFeed(
    List<String> adIds, {
    Map<String, dynamic>? options,
  }) : this(adType: drawFeedType, adIds: adIds, options: options);

  const PreloadConfig.interstitial(
    List<String> adIds, {
    Map<String, dynamic>? options,
  }) : this(adType: interstitialType, adIds: adIds, options: options);

  const PreloadConfig.banner(
    List<String> adIds, {
    Map<String, dynamic>? options,
  }) : this(adType: bannerType, adIds: adIds, options: options);

  Map<String, dynamic> toMap() {
    return {
      'adType': adType,
      'adIds': adIds,
      if (options != null && options!.isNotEmpty) 'options': options,
    };
  }
}

/// 年龄组常量
class AgeGroup {
  const AgeGroup._();

  /// 成人（默认值）
  static const int adult = 0;

  /// 青少年 (15-18岁)
  static const int teenager = 1;

  /// 未成年人 (< 15岁)
  static const int minor = 2;
}

/// 广告事件订阅接口
abstract class AdEventSubscription {
  /// 取消订阅
  void cancel();

  /// 是否仍然活跃
  bool get isActive;
}

/// 基础事件订阅实现
class _AdEventSubscriptionImpl implements AdEventSubscription {
  final String? posIdFilter; // null = 不过滤
  final String? actionPrefix; // 例如 'reward_video_'

  final void Function(AdEvent)? onEvent;
  final void Function(AdErrorEvent)? onError;
  final void Function(AdRewardEvent)? onReward;
  final void Function(AdEcpmEvent)? onEcpm;

  bool _isActive = true;

  _AdEventSubscriptionImpl({
    this.posIdFilter,
    this.actionPrefix,
    this.onEvent,
    this.onError,
    this.onReward,
    this.onEcpm,
  });

  @override
  bool get isActive => _isActive;

  @override
  void cancel() {
    _isActive = false;
    GromoreAds._activeSubscriptions.remove(this);
  }

  void _handleEvent(Map<String, dynamic> payload) {
    if (!_isActive) return;

    // 过滤 posId
    if (posIdFilter != null) {
      final eventPosId = payload['posId'] as String?;
      if (eventPosId != posIdFilter) {
        return; // 不匹配，忽略
      }
    }

    // 过滤 action 前缀（使用局部变量避免 public field 的类型提升问题）
    final prefix = actionPrefix;
    if (prefix != null) {
      final action = payload['action'] as String?;
      if (action == null || !action.startsWith(prefix)) {
        return; // 不匹配，忽略
      }
    }

    // 解析事件类型并回调
    try {
      final action = payload['action'] as String;

      // 检查是否为错误事件
      if (_isErrorEvent(action)) {
        final event = AdErrorEvent.fromMap(payload);
        onError?.call(event);
        onEvent?.call(event);
        return;
      }

      // 检查是否为奖励事件
      if (_isRewardEvent(action)) {
        final event = AdRewardEvent.fromMap(payload);
        onReward?.call(event);
        onEvent?.call(event);
        return;
      }

      // 检查是否为ECPM事件
      if (_isEcpmEvent(payload)) {
        final event = AdEcpmEvent.fromMap(payload);
        onEcpm?.call(event);
        onEvent?.call(event);
        return;
      }

      // 普通事件
      final event = AdEvent.fromMap(payload);
      onEvent?.call(event);
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('gromore_ads: 事件处理异常: $e');
        debugPrintStack(stackTrace: stack);
      }
    }
  }

  bool _isErrorEvent(String action) {
    return action.endsWith('_error') ||
        action.endsWith('_load_error') ||
        action.endsWith('_fail');
  }

  bool _isRewardEvent(String action) {
    return action.startsWith('reward_') && action.endsWith('_rewarded');
  }

  bool _isEcpmEvent(Map<String, dynamic> data) {
    if (data.containsKey('ecpm')) return true;
    final extra = data['extra'];
    return extra is Map && extra.containsKey('ecpm');
  }
}

/// 激励视频订阅实现
class _RewardVideoSubscriptionImpl extends _AdEventSubscriptionImpl {
  final void Function(AdEvent)? onLoaded;
  final void Function(AdEvent)? onShowed;
  final void Function(AdRewardEvent)? onRewarded;
  final void Function(AdEvent)? onCompleted;
  final void Function(AdEvent)? onSkipped;
  final void Function(AdEvent)? onClicked;
  final void Function(AdEvent)? onClosed;

  _RewardVideoSubscriptionImpl({
    required String posId,
    this.onLoaded,
    this.onShowed,
    this.onRewarded,
    this.onCompleted,
    this.onSkipped,
    this.onClicked,
    this.onClosed,
    void Function(AdErrorEvent)? onError,
  }) : super(
          posIdFilter: posId,
          actionPrefix: 'reward_video_',
          onError: onError,
        );

  @override
  void _handleEvent(Map<String, dynamic> payload) {
    if (!isActive) return;

    // 检查posId
    final eventPosId = payload['posId'] as String?;
    if (eventPosId != posIdFilter) return;

    try {
      final action = payload['action'] as String;

      // 错误事件
      if (action == 'reward_video_load_fail') {
        final event = AdErrorEvent.fromMap(payload);
        onError?.call(event);
        return;
      }

      // 奖励事件
      if (action == 'reward_video_rewarded') {
        final event = AdRewardEvent.fromMap(payload);
        onRewarded?.call(event);
        return;
      }

      // 普通事件
      final event = AdEvent.fromMap(payload);
      switch (action) {
        case 'reward_video_loaded':
          onLoaded?.call(event);
          break;
        case 'reward_video_showed':
          onShowed?.call(event);
          break;
        case 'reward_video_completed':
          onCompleted?.call(event);
          break;
        case 'reward_video_skipped':
          onSkipped?.call(event);
          break;
        case 'reward_video_clicked':
          onClicked?.call(event);
          break;
        case 'reward_video_closed':
          onClosed?.call(event);
          break;
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('gromore_ads: 激励视频事件处理异常: $e');
        debugPrintStack(stackTrace: stack);
      }
    }
  }
}

/// 开屏广告订阅实现
class _SplashSubscriptionImpl extends _AdEventSubscriptionImpl {
  final void Function(AdEvent)? onLoaded;
  final void Function(AdEvent)? onShowed;
  final void Function(AdEvent)? onClicked;
  final void Function(AdEvent)? onClosed;

  _SplashSubscriptionImpl({
    required String posId,
    this.onLoaded,
    this.onShowed,
    this.onClicked,
    this.onClosed,
    void Function(AdErrorEvent)? onError,
  }) : super(
          posIdFilter: posId,
          actionPrefix: 'splash_',
          onError: onError,
        );

  @override
  void _handleEvent(Map<String, dynamic> payload) {
    if (!isActive) return;

    final eventPosId = payload['posId'] as String?;
    if (eventPosId != posIdFilter) return;

    try {
      final action = payload['action'] as String;

      if (action == 'splash_load_fail') {
        final event = AdErrorEvent.fromMap(payload);
        onError?.call(event);
        return;
      }

      final event = AdEvent.fromMap(payload);
      switch (action) {
        case 'splash_loaded':
          onLoaded?.call(event);
          break;
        case 'splash_showed':
          onShowed?.call(event);
          break;
        case 'splash_clicked':
          onClicked?.call(event);
          break;
        case 'splash_closed':
          onClosed?.call(event);
          break;
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('gromore_ads: 开屏事件处理异常: $e');
        debugPrintStack(stackTrace: stack);
      }
    }
  }
}

/// 插屏广告订阅实现
class _InterstitialSubscriptionImpl extends _AdEventSubscriptionImpl {
  final void Function(AdEvent)? onLoaded;
  final void Function(AdEvent)? onShowed;
  final void Function(AdEvent)? onClicked;
  final void Function(AdEvent)? onClosed;

  _InterstitialSubscriptionImpl({
    required String posId,
    this.onLoaded,
    this.onShowed,
    this.onClicked,
    this.onClosed,
    void Function(AdErrorEvent)? onError,
  }) : super(
          posIdFilter: posId,
          actionPrefix: 'interstitial_',
          onError: onError,
        );

  @override
  void _handleEvent(Map<String, dynamic> payload) {
    if (!isActive) return;

    final eventPosId = payload['posId'] as String?;
    if (eventPosId != posIdFilter) return;

    try {
      final action = payload['action'] as String;

      if (action == 'interstitial_load_fail') {
        final event = AdErrorEvent.fromMap(payload);
        onError?.call(event);
        return;
      }

      final event = AdEvent.fromMap(payload);
      switch (action) {
        case 'interstitial_loaded':
          onLoaded?.call(event);
          break;
        case 'interstitial_showed':
          onShowed?.call(event);
          break;
        case 'interstitial_clicked':
          onClicked?.call(event);
          break;
        case 'interstitial_closed':
          onClosed?.call(event);
          break;
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('gromore_ads: 插屏事件处理异常: $e');
        debugPrintStack(stackTrace: stack);
      }
    }
  }
}

/// 信息流广告订阅实现
class _FeedSubscriptionImpl extends _AdEventSubscriptionImpl {
  final void Function(AdEvent)? onLoaded;
  final void Function(AdEvent)? onShowed;
  final void Function(AdEvent)? onClicked;
  final void Function(AdEvent)? onClosed;

  _FeedSubscriptionImpl({
    required String posId,
    this.onLoaded,
    this.onShowed,
    this.onClicked,
    this.onClosed,
    void Function(AdErrorEvent)? onError,
  }) : super(
          posIdFilter: posId,
          actionPrefix: 'feed_',
          onError: onError,
        );

  @override
  void _handleEvent(Map<String, dynamic> payload) {
    if (!isActive) return;

    final eventPosId = payload['posId'] as String?;
    if (eventPosId != posIdFilter) return;

    try {
      final action = payload['action'] as String;

      if (action == 'feed_load_fail') {
        final event = AdErrorEvent.fromMap(payload);
        onError?.call(event);
        return;
      }

      final event = AdEvent.fromMap(payload);
      switch (action) {
        case 'feed_loaded':
          onLoaded?.call(event);
          break;
        case 'feed_showed':
          onShowed?.call(event);
          break;
        case 'feed_clicked':
          onClicked?.call(event);
          break;
        case 'feed_closed':
          onClosed?.call(event);
          break;
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('gromore_ads: 信息流事件处理异常: $e');
        debugPrintStack(stackTrace: stack);
      }
    }
  }
}

/// Draw信息流广告订阅实现
class _DrawFeedSubscriptionImpl extends _AdEventSubscriptionImpl {
  final void Function(AdEvent)? onLoaded;
  final void Function(AdEvent)? onShowed;
  final void Function(AdEvent)? onClicked;
  final void Function(AdEvent)? onClosed;

  _DrawFeedSubscriptionImpl({
    required String posId,
    this.onLoaded,
    this.onShowed,
    this.onClicked,
    this.onClosed,
    void Function(AdErrorEvent)? onError,
  }) : super(
          posIdFilter: posId,
          actionPrefix: 'draw_feed_',
          onError: onError,
        );

  @override
  void _handleEvent(Map<String, dynamic> payload) {
    if (!isActive) return;

    final eventPosId = payload['posId'] as String?;
    if (eventPosId != posIdFilter) return;

    try {
      final action = payload['action'] as String;

      if (action == 'draw_feed_load_fail') {
        final event = AdErrorEvent.fromMap(payload);
        onError?.call(event);
        return;
      }

      final event = AdEvent.fromMap(payload);
      switch (action) {
        case 'draw_feed_loaded':
          onLoaded?.call(event);
          break;
        case 'draw_feed_showed':
          onShowed?.call(event);
          break;
        case 'draw_feed_clicked':
          onClicked?.call(event);
          break;
        case 'draw_feed_closed':
          onClosed?.call(event);
          break;
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('gromore_ads: Draw信息流事件处理异常: $e');
        debugPrintStack(stackTrace: stack);
      }
    }
  }
}
