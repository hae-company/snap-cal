import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 광고 모드. 빌드할 때 `--dart-define=ADS=...`로 고른다.
///
/// - [off]: 광고 없음 (기본값)
/// - [test]: 구글 테스트 광고. 돈이 오가지 않는다.
/// - [on]: 실제 광고. `ADMOB_REWARDED_IOS`, `ADMOB_REWARDED_ANDROID`와 실제 앱 ID가 필요하다 (docs/ADS.md).
enum AdsMode {
  off,
  test,
  on;

  static AdsMode parse(String raw) => values.firstWhere(
    (m) => m.name == raw.trim().toLowerCase(),
    orElse: () => off,
  );

  bool get enabled => this != off;
}

/// 광고 하나를 보여준 결과
enum RewardOutcome {
  /// 끝까지 봐서 보상을 받음
  rewarded,

  /// 중간에 닫음
  cancelled,

  /// 광고를 불러오지 못함 (재고 없음, 네트워크 등)
  failed,

  /// 광고가 꺼져 있음
  unavailable,
}

/// 하루에 광고로 받을 수 있는 AI 분석 횟수
const dailyAdRewardLimit = 2;

/// 보상형 광고. 화면은 이 인터페이스만 쓴다.
abstract interface class RewardedAdService {
  AdsMode get mode;

  /// SDK 준비 + 광고 미리 불러오기. 여러 번 불러도 된다.
  Future<void> init();

  /// 광고를 보여주고, 끝까지 봤는지 알려준다.
  Future<RewardOutcome> show();
}

class DisabledRewardedAds implements RewardedAdService {
  @override
  AdsMode get mode => AdsMode.off;

  @override
  Future<void> init() async {}

  @override
  Future<RewardOutcome> show() async => RewardOutcome.unavailable;
}

/// 시험용: 정해진 결과를 바로 돌려준다
class FakeRewardedAds implements RewardedAdService {
  FakeRewardedAds({this.outcome = RewardOutcome.rewarded});
  RewardOutcome outcome;
  int shown = 0;

  @override
  AdsMode get mode => AdsMode.test;

  @override
  Future<void> init() async {}

  @override
  Future<RewardOutcome> show() async {
    shown++;
    return outcome;
  }
}

/// Google AdMob 보상형 광고
class AdMobRewardedAds implements RewardedAdService {
  AdMobRewardedAds({
    required this.mode,
    required this.iosUnitId,
    required this.androidUnitId,
  });

  @override
  final AdsMode mode;
  final String iosUnitId;
  final String androidUnitId;

  /// 구글이 공개한 보상형 테스트 광고 단위
  static const _testIos = 'ca-app-pub-3940256099942544/1712485313';
  static const _testAndroid = 'ca-app-pub-3940256099942544/5224354917';

  Future<void>? _init;
  RewardedAd? _ready;
  Future<RewardedAd?>? _loading;

  String get _unitId {
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    if (mode == AdsMode.test) return ios ? _testIos : _testAndroid;
    return ios ? iosUnitId : androidUnitId;
  }

  @override
  Future<void> init() => _init ??= () async {
    await MobileAds.instance.initialize();
    unawaited(_load());
  }();

  /// 다음 광고를 미리 불러 둔다
  Future<RewardedAd?> _load() {
    if (_ready != null) return Future.value(_ready);
    return _loading ??= () {
      final done = Completer<RewardedAd?>();
      RewardedAd.load(
        adUnitId: _unitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _ready = ad;
            done.complete(ad);
          },
          onAdFailedToLoad: (_) => done.complete(null),
        ),
      );
      return done.future.whenComplete(() => _loading = null);
    }();
  }

  @override
  Future<RewardOutcome> show() async {
    if (_unitId.isEmpty) return RewardOutcome.unavailable;
    await init();
    final ad = await _load().timeout(
      const Duration(seconds: 8),
      onTimeout: () => null,
    );
    if (ad == null) return RewardOutcome.failed;
    _ready = null;

    final result = Completer<RewardOutcome>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!result.isCompleted) {
          result.complete(
            earned ? RewardOutcome.rewarded : RewardOutcome.cancelled,
          );
        }
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        if (!result.isCompleted) result.complete(RewardOutcome.failed);
      },
    );
    await ad.show(onUserEarnedReward: (_, _) => earned = true);
    final outcome = await result.future;
    unawaited(_load()); // 다음 광고 미리 준비
    return outcome;
  }
}
