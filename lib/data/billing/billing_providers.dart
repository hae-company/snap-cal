import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/config.dart';
import '../../core/date_key.dart';
import '../ads/rewarded_ads.dart';
import '../providers.dart';
import '../repositories/settings_repository.dart';
import 'billing_models.dart';
import 'billing_service.dart';
import 'revenuecat_billing_service.dart';

final billingServiceProvider = Provider<BillingService>((ref) {
  return switch (BillingMode.parse(AppConfig.billing)) {
    BillingMode.off => DisabledBillingService(),
    BillingMode.mock => MockBillingService(
      ref.watch(sharedPreferencesProvider),
    ),
    BillingMode.revenuecat => RevenueCatBillingService(
      iosKey: AppConfig.revenueCatIosKey,
      androidKey: AppConfig.revenueCatAndroidKey,
    ),
  };
});

/// 구독 상태. 구매·복원·외부 변경(만료, 다른 기기 구매)을 반영한다.
class EntitlementNotifier extends AsyncNotifier<Entitlement> {
  StreamSubscription<Entitlement>? _sub;

  BillingService get _billing => ref.read(billingServiceProvider);

  @override
  Future<Entitlement> build() async {
    final billing = ref.watch(billingServiceProvider);
    _sub?.cancel();
    _sub = billing.changes.listen((e) => state = AsyncData(e));
    ref.onDispose(() => _sub?.cancel());
    try {
      await billing.init();
      return await billing.current();
    } catch (_) {
      // 결제 SDK 문제로 앱 전체가 막히지 않게 무료로 둔다
      return Entitlement.none;
    }
  }

  Future<PurchaseOutcome> purchase(Plan plan) async {
    final outcome = await _billing.purchase(plan);
    if (outcome is PurchaseSuccess) state = AsyncData(outcome.entitlement);
    return outcome;
  }

  Future<Entitlement> restore() async {
    final e = await _billing.restore();
    state = AsyncData(e);
    return e;
  }
}

final entitlementProvider =
    AsyncNotifierProvider<EntitlementNotifier, Entitlement>(
      EntitlementNotifier.new,
    );

/// 지금 사용자가 쓸 수 있는 범위
enum AccessLevel {
  /// 결제·광고 모두 꺼짐: 모든 기능 무제한 무료
  open,

  /// 광고 전용 모드 (구독 판매 없음, 사업자 없이 출시할 때):
  /// 기능은 모두 열려 있고, AI 분석만 무료 3회 + 광고 보상으로 제한
  adSupported,

  /// 구독 모드의 무료 사용자
  free,
  premium;

  /// 체중 그래프·CSV 같은 프리미엄 기능을 쓸 수 있는지
  bool get unlocked => this != free;

  /// AI 분석 횟수를 세는지 (무료 3회 + 광고 보상)
  bool get analysisLimited => this == free || this == adSupported;
}

final accessLevelProvider = Provider<AccessLevel>((ref) {
  if (!ref.watch(billingServiceProvider).mode.enforcesPremium) {
    // 구독은 없지만 광고가 켜져 있으면 광고 전용 모드
    return ref.watch(rewardedAdsProvider).mode.enabled
        ? AccessLevel.adSupported
        : AccessLevel.open;
  }
  final premium = ref.watch(entitlementProvider).value?.premium ?? false;
  return premium ? AccessLevel.premium : AccessLevel.free;
});

/// 무료 사용자가 쓴 AI 분석 횟수 (평생)
class FreeAnalysesNotifier extends Notifier<int> {
  @override
  int build() => ref.watch(settingsRepositoryProvider).freeAnalysesUsed;

  /// 분석에 성공했을 때 한 번 센다 (무료 사용자만).
  /// 무료 체험을 먼저 쓰고, 다 쓴 뒤에는 광고로 받은 횟수를 쓴다.
  Future<void> recordUse() async {
    if (!ref.read(accessLevelProvider).analysisLimited) return;
    if (state < freeAnalysisLimit) {
      state = state + 1;
      await ref.read(settingsRepositoryProvider).setFreeAnalysesUsed(state);
    } else {
      await ref.read(adRewardsProvider.notifier).consume();
    }
  }
}

final freeAnalysesUsedProvider = NotifierProvider<FreeAnalysesNotifier, int>(
  FreeAnalysesNotifier.new,
);

/// 광고 보상: 남은 보너스 횟수와 오늘 광고 본 횟수
class AdRewards {
  const AdRewards({required this.bonus, required this.today});
  final int bonus;
  final int today;
}

class AdRewardsNotifier extends Notifier<AdRewards> {
  SettingsRepository get _repo => ref.read(settingsRepositoryProvider);
  String get _today => dateKey(DateTime.now());

  @override
  AdRewards build() {
    final repo = ref.watch(settingsRepositoryProvider);
    return AdRewards(
      bonus: repo.bonusAnalyses,
      today: repo.adRewardsOn(dateKey(DateTime.now())),
    );
  }

  /// 광고를 끝까지 봤을 때 분석 1회를 준다. 하루 한도를 넘으면 false.
  Future<bool> grant() async {
    final today = _repo.adRewardsOn(_today);
    if (today >= dailyAdRewardLimit) return false;
    await _repo.setAdRewards(_today, today + 1);
    await _repo.setBonusAnalyses(_repo.bonusAnalyses + 1);
    state = AdRewards(bonus: _repo.bonusAnalyses, today: today + 1);
    return true;
  }

  Future<void> consume() async {
    final next = (_repo.bonusAnalyses - 1).clamp(0, 1 << 30);
    await _repo.setBonusAnalyses(next);
    state = AdRewards(bonus: next, today: _repo.adRewardsOn(_today));
  }
}

final adRewardsProvider = NotifierProvider<AdRewardsNotifier, AdRewards>(
  AdRewardsNotifier.new,
);

final rewardedAdsProvider = Provider<RewardedAdService>((ref) {
  final mode = AdsMode.parse(AppConfig.ads);
  if (!mode.enabled) return DisabledRewardedAds();
  return AdMobRewardedAds(
    mode: mode,
    iosUnitId: AppConfig.admobRewardedIos,
    androidUnitId: AppConfig.admobRewardedAndroid,
  );
});

/// 광고가 켜져 있으면 앱 시작 때 SDK를 준비하고 광고를 미리 불러 둔다
final adsWarmupProvider = FutureProvider<void>((ref) async {
  try {
    await ref.watch(rewardedAdsProvider).init();
  } catch (_) {
    // 광고 문제로 앱이 멈추지 않게 무시
  }
});

/// 지금 광고를 보고 분석 1회를 받을 수 있는지 (광고 켜짐 + 무료 사용자 + 오늘 한도 안)
final canWatchAdProvider = Provider<bool>((ref) {
  if (!ref.watch(rewardedAdsProvider).mode.enabled) return false;
  if (!ref.watch(accessLevelProvider).analysisLimited) return false;
  return ref.watch(adRewardsProvider).today < dailyAdRewardLimit;
});

/// 무료 사용자에게 남은 AI 분석 횟수 (체험 + 광고 보너스). 무제한이면 null.
final remainingFreeAnalysesProvider = Provider<int?>((ref) {
  if (!ref.watch(accessLevelProvider).analysisLimited) return null;
  final int used = ref.watch(freeAnalysesUsedProvider);
  final trial = freeAnalysisLimit - used;
  return (trial < 0 ? 0 : trial) + ref.watch(adRewardsProvider).bonus;
});
