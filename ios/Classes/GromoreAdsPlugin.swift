import Flutter
import UIKit
import BUAdSDK
#if DEBUG
import BUAdTestMeasurement
#endif
import AppTrackingTransparency
import AdSupport

public class GromoreAdsPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    
    // 方法通道
    private var methodChannel: FlutterMethodChannel?
    // 事件通道
    private var eventChannel: FlutterEventChannel?
    // 事件回调
    private var eventSink: FlutterEventSink?
    
    // 工具类实例
    private let eventHelper = AdEventHelper.shared
    private let validationHelper = AdValidationHelper.shared
    private let logger = AdLogger.shared
    
    // Flutter插件注册器（用于访问Assets）
    private var flutterRegistrar: FlutterPluginRegistrar?
    
    // SDK管理器和广告管理器实例
    private var sdkManager: SdkManager!
    private lazy var splashAdManager: SplashAdManager = {
        return SplashAdManager(registrar: self.flutterRegistrar)
    }()
    private lazy var interstitialAdManager = InterstitialAdManager()
    private lazy var rewardVideoAdManager = RewardVideoAdManager()
    private lazy var feedAdManager = FeedAdManager()
    private lazy var drawFeedAdManager = DrawFeedAdManager()
    private lazy var bannerAdManager = BannerAdManager()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(name: "gromore_ads", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "gromore_ads_event", binaryMessenger: registrar.messenger())
        
        let instance = GromoreAdsPlugin()
        instance.methodChannel = methodChannel
        instance.eventChannel = eventChannel
        instance.flutterRegistrar = registrar  // 保存registrar引用
        instance.sdkManager = SdkManager(registrar: registrar)
        
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
        
        // 注册原生视图工厂
        let bannerFactory = GromoreAdsBannerViewFactory(messenger: registrar.messenger())
        registrar.register(bannerFactory, withId: "gromore_ads_banner")
        
        let feedFactory = GromoreAdsFeedViewFactory(
            messenger: registrar.messenger(),
            feedAdManager: instance.feedAdManager,
            eventHelper: instance.eventHelper,
            logger: instance.logger
        )
        registrar.register(feedFactory, withId: "gromore_ads_feed")

        let drawFactory = GromoreAdsDrawFeedViewFactory(
            messenger: registrar.messenger(),
            drawAdManager: instance.drawFeedAdManager,
            eventHelper: instance.eventHelper,
            logger: instance.logger
        )
        registrar.register(drawFactory, withId: "gromore_ads_draw_feed")
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        // SDK管理相关（路由到SdkManager）
        case "requestIDFA":
            sdkManager.requestIDFA(result: result)
        case "initAd":
            sdkManager.initAd(call, result: result)
        case "preload":
            sdkManager.preload(call, result: result)
            
        // 开屏广告
        case "showSplashAd":
            splashAdManager.show(call, result: result)
            
        // 插屏广告（分离式）
        case "loadInterstitialAd":
            interstitialAdManager.load(call, result: result)
        case "showInterstitialAd":
            interstitialAdManager.show(call, result: result)
            
        // 激励视频广告（分离式）
        case "loadRewardVideoAd":
            rewardVideoAdManager.load(call, result: result)
        case "showRewardVideoAd":
            rewardVideoAdManager.show(call, result: result)
            
        // 信息流广告
        case "loadFeedAd":
            feedAdManager.loadBatch(call, result: result)
        case "clearFeedAd":
            feedAdManager.clearBatch(call, result: result)
        case "loadDrawFeedAd":
            drawFeedAdManager.loadBatch(call, result: result)
        case "clearDrawFeedAd":
            drawFeedAdManager.clearBatch(call, result: result)
        
        // Banner广告
        case "loadBannerAd":
            bannerAdManager.load(call, result: result)
        case "showBannerAd":
            bannerAdManager.show(call, result: result)
        case "destroyBannerAd":
            bannerAdManager.destroy(call, result: result)

        // 测试工具（路由到SdkManager）
        case "launchTestTools":
            sdkManager.launchTestTools(call, result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - FlutterStreamHandler
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        eventHelper.updateEventSink(events)
        logger.logInfo("事件通道已连接")
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        eventHelper.updateEventSink(nil)
        logger.logInfo("事件通道已断开")
        return nil
    }
}
