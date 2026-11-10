import 'package:flutter/foundation.dart';

/// 빌드할 때 `--dart-define`으로 넣는 설정값.
///
/// 결제·광고는 기본으로 **켜져 있다**.
/// - 개발 빌드(flutter run 등): 가짜 결제 + 구글 테스트 광고
/// - 출시 빌드(--release): 키·광고 ID가 있으면 실제 결제·실제 광고, 없으면 꺼짐
///   (가짜 결제가 실수로 출시되지 않게 출시 빌드에서는 mock을 쓰지 않는다)
///
/// 직접 고르려면: `--dart-define=BILLING=off|mock|revenuecat`, `--dart-define=ADS=off|test|on`
///
/// 예) 실제 결제·광고로 출시 빌드:
///   flutter build ipa --dart-define=RC_IOS_KEY=appl_xxx --dart-define=RC_ANDROID_KEY=goog_xxx \
///     --dart-define=ADMOB_REWARDED_IOS=ca-app-pub-... --dart-define=ADMOB_REWARDED_ANDROID=ca-app-pub-...
abstract final class AppConfig {
  static const _billingFlag = String.fromEnvironment('BILLING');
  static const _adsFlag = String.fromEnvironment('ADS');

  static const revenueCatIosKey = String.fromEnvironment('RC_IOS_KEY');
  static const revenueCatAndroidKey = String.fromEnvironment('RC_ANDROID_KEY');

  /// AdMob 보상형 광고 단위 ID (실제 광고일 때만 씀)
  static const admobRewardedIos = String.fromEnvironment('ADMOB_REWARDED_IOS');
  static const admobRewardedAndroid = String.fromEnvironment(
    'ADMOB_REWARDED_ANDROID',
  );

  /// 약관·개인정보처리방침 웹 주소 (스토어 심사에서 페이월에 링크 필요). 비어 있으면 앱 안 원문을 보여준다.
  static const termsUrl = String.fromEnvironment('TERMS_URL');
  static const privacyUrl = String.fromEnvironment('PRIVACY_URL');

  static bool get _hasRevenueCatKeys =>
      revenueCatIosKey.isNotEmpty || revenueCatAndroidKey.isNotEmpty;
  static bool get _hasAdUnits =>
      admobRewardedIos.isNotEmpty || admobRewardedAndroid.isNotEmpty;

  /// off · mock · revenuecat
  static String get billing => resolveBilling(
    _billingFlag,
    release: kReleaseMode,
    hasKeys: _hasRevenueCatKeys,
  );

  /// off · test · on
  static String get ads =>
      resolveAds(_adsFlag, release: kReleaseMode, hasAdUnits: _hasAdUnits);
}

/// 결제 모드 결정. 시험할 수 있게 함수로 뺐다.
String resolveBilling(
  String flag, {
  required bool release,
  required bool hasKeys,
}) {
  final f = flag.trim().toLowerCase();
  if (release) {
    if (f == 'mock') return 'off'; // 가짜 결제는 출시 빌드에서 쓰지 않는다
    if (f.isNotEmpty) return f;
    return hasKeys ? 'revenuecat' : 'off';
  }
  return f.isNotEmpty ? f : 'mock';
}

/// 광고 모드 결정
String resolveAds(
  String flag, {
  required bool release,
  required bool hasAdUnits,
}) {
  final f = flag.trim().toLowerCase();
  if (f.isNotEmpty) return f;
  if (release) return hasAdUnits ? 'on' : 'off';
  return 'test';
}
