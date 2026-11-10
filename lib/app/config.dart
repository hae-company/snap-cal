/// 빌드할 때 `--dart-define`으로 넣는 설정값.
///
/// 예) 실제 결제로 빌드:
///   flutter run --dart-define=BILLING=revenuecat \
///     --dart-define=RC_IOS_KEY=appl_xxx --dart-define=RC_ANDROID_KEY=goog_xxx
abstract final class AppConfig {
  /// off(기본, 결제 준비 중) · mock(가짜 결제) · revenuecat(실제 결제)
  static const billing = String.fromEnvironment('BILLING', defaultValue: 'off');

  static const revenueCatIosKey = String.fromEnvironment('RC_IOS_KEY');
  static const revenueCatAndroidKey = String.fromEnvironment('RC_ANDROID_KEY');

  /// 약관·개인정보처리방침 웹 주소 (스토어 심사에서 페이월에 링크 필요). 비어 있으면 앱 안 원문을 보여준다.
  static const termsUrl = String.fromEnvironment('TERMS_URL');
  static const privacyUrl = String.fromEnvironment('PRIVACY_URL');
}
