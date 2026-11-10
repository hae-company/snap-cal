import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/config.dart';
import '../providers.dart';
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
  /// 결제 준비 중: 모든 기능 무료
  open,
  free,
  premium;

  bool get unlocked => this != free;
}

final accessLevelProvider = Provider<AccessLevel>((ref) {
  if (!ref.watch(billingServiceProvider).mode.enforcesPremium) {
    return AccessLevel.open;
  }
  final premium = ref.watch(entitlementProvider).value?.premium ?? false;
  return premium ? AccessLevel.premium : AccessLevel.free;
});

/// 무료 사용자가 쓴 AI 분석 횟수 (평생)
class FreeAnalysesNotifier extends Notifier<int> {
  @override
  int build() => ref.watch(settingsRepositoryProvider).freeAnalysesUsed;

  /// 분석에 성공했을 때 한 번 센다 (무료 사용자만)
  Future<void> recordUse() async {
    if (ref.read(accessLevelProvider) != AccessLevel.free) return;
    state = state + 1;
    await ref.read(settingsRepositoryProvider).setFreeAnalysesUsed(state);
  }
}

final freeAnalysesUsedProvider = NotifierProvider<FreeAnalysesNotifier, int>(
  FreeAnalysesNotifier.new,
);

/// 무료 사용자에게 남은 AI 분석 횟수. 무제한이면 null.
final remainingFreeAnalysesProvider = Provider<int?>((ref) {
  if (ref.watch(accessLevelProvider) != AccessLevel.free) return null;
  final int used = ref.watch(freeAnalysesUsedProvider);
  final left = freeAnalysisLimit - used;
  return left < 0 ? 0 : left;
});
