/// 결제 모드. 빌드할 때 `--dart-define=BILLING=...`로 고른다.
///
/// - [off]: 결제 준비 중. 모든 기능이 무료로 열려 있고, 페이월은 미리보기로만 보인다. (기본값)
/// - [mock]: 가짜 결제. 실제 돈 없이 결제·체험·복원 흐름을 시험한다.
/// - [revenuecat]: 실제 결제. RevenueCat 키가 필요하다 (docs/BILLING.md).
enum BillingMode {
  off,
  mock,
  revenuecat;

  static BillingMode parse(String raw) => values.firstWhere(
    (m) => m.name == raw.trim().toLowerCase(),
    orElse: () => off,
  );

  /// 프리미엄 잠금을 실제로 거는지
  bool get enforcesPremium => this != off;
}

/// 프리미엄으로 여는 기능
enum PremiumFeature {
  unlimitedAnalysis('AI 사진 분석 무제한'),
  weightTrend('체중 추이 그래프'),
  csvExport('식단 기록 내보내기');

  const PremiumFeature(this.label);
  final String label;
}

/// 무료 사용자에게 주는 AI 분석 체험 횟수 (평생)
const freeAnalysisLimit = 3;

enum PlanPeriod { yearly, monthly }

/// 페이월에 보여줄 상품
class Plan {
  const Plan({
    required this.id,
    required this.period,
    required this.priceLabel,
    this.perMonthLabel,
    this.trialDays = 0,
    this.handle,
  });

  final String id;
  final PlanPeriod period;

  /// 스토어가 준 가격 문자열 (예: ₩39,000)
  final String priceLabel;

  /// 연간 상품의 월 환산 가격 (예: 월 3,250원)
  final String? perMonthLabel;

  /// 무료 체험 일수. 없으면 0.
  final int trialDays;

  /// 결제 구현이 쓰는 원본 객체 (RevenueCat Package 등)
  final Object? handle;

  String get periodLabel => period == PlanPeriod.yearly ? '연간' : '월간';
}

/// 지금 사용자의 구독 상태
class Entitlement {
  const Entitlement({
    required this.premium,
    this.inTrial = false,
    this.expiresAt,
    this.willRenew = false,
    this.productId,
    this.managementUrl,
  });

  static const none = Entitlement(premium: false);

  final bool premium;
  final bool inTrial;
  final DateTime? expiresAt;
  final bool willRenew;
  final String? productId;

  /// 스토어 구독 관리 페이지
  final String? managementUrl;
}

sealed class PurchaseOutcome {
  const PurchaseOutcome();
}

class PurchaseSuccess extends PurchaseOutcome {
  const PurchaseSuccess(this.entitlement);
  final Entitlement entitlement;
}

class PurchaseCancelled extends PurchaseOutcome {
  const PurchaseCancelled();
}

class PurchaseFailed extends PurchaseOutcome {
  const PurchaseFailed(this.message);
  final String message;
}

/// 결제가 아직 열리지 않음 ([BillingMode.off])
class PurchaseUnavailable extends PurchaseOutcome {
  const PurchaseUnavailable();
}
