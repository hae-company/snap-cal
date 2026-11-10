import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import 'billing_models.dart';

/// 구독 결제. 화면은 이 인터페이스만 쓴다.
abstract interface class BillingService {
  BillingMode get mode;

  /// SDK 준비. 여러 번 불러도 된다.
  Future<void> init();

  Future<Entitlement> current();

  /// 구독 상태가 바뀔 때 (다른 기기 구매, 만료 등)
  Stream<Entitlement> get changes;

  Future<List<Plan>> plans();
  Future<PurchaseOutcome> purchase(Plan plan);
  Future<Entitlement> restore();
}

/// 설계서 2.2의 가격. 결제가 꺼져 있거나 가짜 결제일 때 페이월에 보여준다.
const designPlans = [
  Plan(
    id: 'caloriesnap_premium_yearly',
    period: PlanPeriod.yearly,
    priceLabel: '₩39,000',
    perMonthLabel: '월 3,250원',
    trialDays: 7,
  ),
  Plan(
    id: 'caloriesnap_premium_monthly',
    period: PlanPeriod.monthly,
    priceLabel: '₩5,900',
  ),
];

/// 결제 준비 중. 구매는 막고, 잠금도 걸지 않는다.
class DisabledBillingService implements BillingService {
  @override
  BillingMode get mode => BillingMode.off;

  @override
  Future<void> init() async {}

  @override
  Future<Entitlement> current() async => Entitlement.none;

  @override
  Stream<Entitlement> get changes => const Stream.empty();

  @override
  Future<List<Plan>> plans() async => designPlans;

  @override
  Future<PurchaseOutcome> purchase(Plan plan) async =>
      const PurchaseUnavailable();

  @override
  Future<Entitlement> restore() async => Entitlement.none;
}

/// 가짜 결제. 기기에 구독 상태를 저장해 결제 흐름을 시험한다.
class MockBillingService implements BillingService {
  MockBillingService(this._prefs, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final SharedPreferences _prefs;
  final DateTime Function() _now;
  final _changes = StreamController<Entitlement>.broadcast();

  static const _kProduct = 'mock_premium_product';
  static const _kExpires = 'mock_premium_expires';
  static const _kTrial = 'mock_premium_trial';

  @override
  BillingMode get mode => BillingMode.mock;

  @override
  Future<void> init() async {}

  @override
  Future<Entitlement> current() async {
    final product = _prefs.getString(_kProduct);
    final expires = DateTime.tryParse(_prefs.getString(_kExpires) ?? '');
    if (product == null || expires == null || !expires.isAfter(_now())) {
      return Entitlement.none;
    }
    return Entitlement(
      premium: true,
      inTrial: _prefs.getBool(_kTrial) ?? false,
      expiresAt: expires,
      willRenew: true,
      productId: product,
    );
  }

  @override
  Stream<Entitlement> get changes => _changes.stream;

  @override
  Future<List<Plan>> plans() async => designPlans;

  @override
  Future<PurchaseOutcome> purchase(Plan plan) async {
    final trial = plan.trialDays > 0;
    final length = trial
        ? Duration(days: plan.trialDays)
        : plan.period == PlanPeriod.yearly
        ? const Duration(days: 365)
        : const Duration(days: 30);
    await _prefs.setString(_kProduct, plan.id);
    await _prefs.setString(_kExpires, _now().add(length).toIso8601String());
    await _prefs.setBool(_kTrial, trial);
    final e = await current();
    _changes.add(e);
    return PurchaseSuccess(e);
  }

  @override
  Future<Entitlement> restore() => current();

  /// 시험용: 구독 지우기
  Future<void> reset() async {
    await _prefs.remove(_kProduct);
    await _prefs.remove(_kExpires);
    await _prefs.remove(_kTrial);
    _changes.add(Entitlement.none);
  }
}
