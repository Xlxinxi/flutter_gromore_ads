import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gromore_ads/gromore_ads.dart';
import 'package:gromore_ads/gromore_ads_platform_interface.dart';
import 'package:gromore_ads/gromore_ads_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockGromoreAdsPlatform
    with MockPlatformInterfaceMixin
    implements GromoreAdsPlatform {
  MockGromoreAdsPlatform();

  final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<Map<String, dynamic>> get adEventStream => _controller.stream;

  @override
  Future<bool> requestIdfa() => Future.value(true);

  @override
  Future<bool> requestPermissionIfNecessary() => Future.value(true);

  @override
  Future<bool> initAd(Map<String, dynamic> params) => Future.value(true);

  @override
  Future<bool> preload(Map<String, dynamic> params) => Future.value(true);

  @override
  Future<bool> showSplashAd(Map<String, dynamic> params) => Future.value(true);

  @override
  Future<bool> loadInterstitialAd(Map<String, dynamic> params) =>
      Future.value(true);

  @override
  Future<bool> showInterstitialAd(String posId) => Future.value(true);

  @override
  Future<bool> loadRewardVideoAd(Map<String, dynamic> params) =>
      Future.value(true);

  @override
  Future<bool> showRewardVideoAd(String posId) => Future.value(true);

  @override
  Future<List<int>> loadFeedAd(Map<String, dynamic> params) =>
      Future.value(const <int>[]);

  @override
  Future<bool> clearFeedAd(List<int> ids) => Future.value(true);

  @override
  Future<List<int>> loadDrawFeedAd(Map<String, dynamic> params) =>
      Future.value(const <int>[]);

  @override
  Future<bool> clearDrawFeedAd(List<int> ids) => Future.value(true);

  @override
  Future<bool> loadBannerAd(Map<String, dynamic> params) => Future.value(true);

  @override
  Future<bool> showBannerAd() => Future.value(true);

  @override
  Future<bool> destroyBannerAd() => Future.value(true);

  @override
  Future<bool> launchTestTools() => Future.value(true);

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final GromoreAdsPlatform initialPlatform = GromoreAdsPlatform.instance;

  test('$MethodChannelGromoreAds is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelGromoreAds>());
  });

  test('getPlatformVersion', () async {
    MockGromoreAdsPlatform fakePlatform = MockGromoreAdsPlatform();
    GromoreAdsPlatform.instance = fakePlatform;

    expect(await GromoreAds.getPlatformVersion, '42');
  });
}
