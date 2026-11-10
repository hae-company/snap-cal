import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart' as rc;

import 'billing_models.dart';
import 'billing_service.dart';

/// RevenueCat 실제 결제.
///
/// 켜는 방법은 docs/BILLING.md. RevenueCat 대시보드 설정:
/// - entitlement: `premium`
/// - 현재 offering에 annual(연간, 7일 체험), monthly(월간) 패키지
class RevenueCatBillingService implements BillingService {
  RevenueCatBillingService({required this.iosKey, required this.androidKey});

  final String iosKey;
  final String androidKey;

  static const entitlementId = 'premium';

  final _changes = StreamController<Entitlement>.broadcast();
  Future<void>? _init;

  @override
  BillingMode get mode => BillingMode.revenuecat;

  @override
  Future<void> init() => _init ??= _configure();

  Future<void> _configure() async {
    final key = defaultTargetPlatform == TargetPlatform.iOS
        ? iosKey
        : androidKey;
    if (key.isEmpty) {
      throw StateError(
        'RevenueCat 키가 없어요. --dart-define=RC_IOS_KEY / RC_ANDROID_KEY 를 넣어주세요.',
      );
    }
    if (kDebugMode) await rc.Purchases.setLogLevel(rc.LogLevel.debug);
    // 로그인이 없으므로 RevenueCat 익명 ID를 쓴다. 기기를 바꾸면 '구매 복원'으로 되찾는다.
    await rc.Purchases.configure(rc.PurchasesConfiguration(key));
    rc.Purchases.addCustomerInfoUpdateListener(
      (info) => _changes.add(entitlementFrom(info)),
    );
  }

  @override
  Future<Entitlement> current() async {
    await init();
    return entitlementFrom(await rc.Purchases.getCustomerInfo());
  }

  @override
  Stream<Entitlement> get changes => _changes.stream;

  @override
  Future<List<Plan>> plans() async {
    await init();
    final offering = (await rc.Purchases.getOfferings()).current;
    if (offering == null) return const [];
    return [
      if (offering.annual case final p?) planFrom(p, PlanPeriod.yearly),
      if (offering.monthly case final p?) planFrom(p, PlanPeriod.monthly),
    ];
  }

  @override
  Future<PurchaseOutcome> purchase(Plan plan) async {
    await init();
    final package = plan.handle;
    if (package is! rc.Package) return const PurchaseFailed('상품 정보를 불러오지 못했어요');
    try {
      final result = await rc.Purchases.purchase(
        rc.PurchaseParams.package(package),
      );
      return PurchaseSuccess(entitlementFrom(result.customerInfo));
    } on PlatformException catch (e) {
      final code = rc.PurchasesErrorHelper.getErrorCode(e);
      if (code == rc.PurchasesErrorCode.purchaseCancelledError) {
        return const PurchaseCancelled();
      }
      return PurchaseFailed(e.message ?? '결제에 실패했어요');
    }
  }

  @override
  Future<Entitlement> restore() async {
    await init();
    return entitlementFrom(await rc.Purchases.restorePurchases());
  }

  static Entitlement entitlementFrom(rc.CustomerInfo info) {
    final e = info.entitlements.active[entitlementId];
    if (e == null || !e.isActive) return Entitlement.none;
    return Entitlement(
      premium: true,
      inTrial: e.periodType == rc.PeriodType.trial,
      expiresAt: e.expirationDate == null
          ? null
          : DateTime.tryParse(e.expirationDate!),
      willRenew: e.willRenew,
      productId: e.productIdentifier,
      managementUrl: info.managementURL,
    );
  }

  static Plan planFrom(rc.Package p, PlanPeriod period) {
    final product = p.storeProduct;
    final intro = product.introductoryPrice;
    final trialDays = intro != null && intro.price == 0
        ? trialLengthDays(intro.periodUnit.name, intro.periodNumberOfUnits) *
              intro.cycles
        : 0;
    return Plan(
      id: product.identifier,
      period: period,
      priceLabel: product.priceString,
      perMonthLabel: period == PlanPeriod.yearly
          ? perMonth(product.price, product.currencyCode)
          : null,
      trialDays: trialDays,
      handle: p,
    );
  }
}

/// 체험 기간 단위를 일수로 (day, week, month, year)
int trialLengthDays(String unit, int count) => switch (unit) {
  'day' => count,
  'week' => count * 7,
  'month' => count * 30,
  'year' => count * 365,
  _ => 0,
};

/// 연간 가격의 월 환산 문구. 원화는 10원 단위로 내린다.
String? perMonth(double yearlyPrice, String currencyCode) {
  if (yearlyPrice <= 0) return null;
  final m = yearlyPrice / 12;
  if (currencyCode == 'KRW') {
    final won = (m / 10).floor() * 10;
    final s = won.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return '월 $s원';
  }
  return '월 ${m.toStringAsFixed(2)} $currencyCode';
}
