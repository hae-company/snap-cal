import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/tokens.dart';
import '../../data/billing/billing_models.dart';
import '../../data/ads/rewarded_ads.dart';
import '../../data/billing/billing_providers.dart';
import '../../shared/widgets/brand.dart';
import '../my/policy_links.dart';

/// 어디서 페이월을 열었는지 (분석 지표용)
enum PaywallSource { onboarding, limit, feature, my }

/// 페이월을 닫은 이유
enum PaywallResult {
  /// 구독(또는 복원)함
  subscribed,

  /// "AI 없이 직접 기록하기"를 고름
  manualEntry,

  /// 광고를 끝까지 보고 분석 1회를 받음
  rewarded,
  closed,
}

final _plansProvider = FutureProvider<List<Plan>>(
  (ref) => ref.watch(billingServiceProvider).plans(),
);

/// 프리미엄 구독 화면. 닫힐 때 [PaywallResult]를 돌려준다.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({
    super.key,
    this.source = PaywallSource.my,
    this.feature,
  });
  final PaywallSource source;
  final PremiumFeature? feature;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  Plan? _selected;
  bool _busy = false;

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _buy(Plan plan) async {
    setState(() => _busy = true);
    final outcome = await ref.read(entitlementProvider.notifier).purchase(plan);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (outcome) {
      case PurchaseSuccess():
        HapticFeedback.mediumImpact();
        _toast(
          plan.trialDays > 0
              ? '${plan.trialDays}일 무료 체험을 시작했어요'
              : '프리미엄을 시작했어요',
        );
        context.pop(PaywallResult.subscribed);
      case PurchaseCancelled():
        break;
      case PurchaseFailed(:final message):
        _toast(message);
      case PurchaseUnavailable():
        _toast('결제는 출시와 함께 열려요. 지금은 모든 기능을 무료로 쓸 수 있어요.');
    }
  }

  Future<void> _watchAd() async {
    setState(() => _busy = true);
    final outcome = await ref.read(rewardedAdsProvider).show();
    if (!mounted) return;
    setState(() => _busy = false);
    switch (outcome) {
      case RewardOutcome.rewarded:
        if (await ref.read(adRewardsProvider.notifier).grant()) {
          HapticFeedback.mediumImpact();
          _toast('AI 분석 1회를 받았어요');
          if (mounted) context.pop(PaywallResult.rewarded);
        } else {
          _toast('오늘 광고 보상은 모두 받았어요. 내일 다시 받을 수 있어요.');
        }
      case RewardOutcome.cancelled:
        _toast('광고를 끝까지 봐야 1회를 받을 수 있어요');
      case RewardOutcome.failed:
        _toast('지금은 보여줄 광고가 없어요. 잠시 후 다시 시도해주세요.');
      case RewardOutcome.unavailable:
        break;
    }
  }

  /// 광고 전용 모드의 "무료 분석을 다 썼어요" 화면
  Widget _adsOnly(BuildContext context) {
    final p = context.palette;
    final canWatch = ref.watch(canWatchAdProvider);
    final today = ref.watch(adRewardsProvider).today;
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.xl,
            0,
            AppSpace.xl,
            AppSpace.md,
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: _busy
                      ? null
                      : () => context.pop(PaywallResult.closed),
                  tooltip: '닫기',
                  icon: Icon(Icons.close_rounded, color: p.text2),
                ),
              ),
              const Spacer(),
              const LogoTile(size: 88),
              const SizedBox(height: AppSpace.lg),
              Text(
                canWatch ? '무료 분석을 다 썼어요' : '오늘 받을 수 있는 분석을 다 썼어요',
                textAlign: TextAlign.center,
                style: AppText.title1,
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                canWatch
                    ? '짧은 광고를 끝까지 보면 AI 분석 1회를 드려요.\n하루 $dailyAdRewardLimit회까지 받을 수 있어요.'
                    : '내일 다시 광고로 $dailyAdRewardLimit회 받을 수 있어요.\n지금은 사진과 함께 직접 기록해 주세요.',
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(color: p.text2),
              ),
              const Spacer(),
              if (canWatch) ...[
                FilledButton.icon(
                  onPressed: _busy ? null : _watchAd,
                  icon: _busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_circle_rounded),
                  label: Text('광고 보고 1회 더 받기 (오늘 $today/$dailyAdRewardLimit)'),
                ),
                const SizedBox(height: AppSpace.sm),
              ],
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => context.pop(PaywallResult.manualEntry),
                icon: Icon(Icons.search_rounded, color: p.brand),
                label: const Text('AI 없이 사진과 함께 직접 기록하기'),
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                '음식 검색과 직접 입력은 언제나 무료예요',
                style: AppText.caption.copyWith(color: p.text3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    final e = await ref.read(entitlementProvider.notifier).restore();
    if (!mounted) return;
    setState(() => _busy = false);
    if (e.premium) {
      _toast('구독을 복원했어요');
      context.pop(PaywallResult.subscribed);
    } else {
      _toast('복원할 구독이 없어요');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(billingServiceProvider).mode;
    // 광고 전용 모드: 구독 판매 없이 광고·직접 기록만 안내
    if (ref.watch(accessLevelProvider) == AccessLevel.adSupported) {
      return _adsOnly(context);
    }
    final plans = ref.watch(_plansProvider);

    return Theme(
      data: Theme.of(context),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: context.palette.bg,
          body: Stack(
            children: [
              Positioned(
                top: -140,
                left: -80,
                right: -80,
                child: Container(
                  height: 420,
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      colors: [Color(0x33FF9A52), Color(0x00FF9A52)],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: plans.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppBrand.orange),
                  ),
                  error: (_, _) =>
                      _Error(onRetry: () => ref.invalidate(_plansProvider)),
                  data: (list) => list.isEmpty
                      ? _Error(onRetry: () => ref.invalidate(_plansProvider))
                      : _content(list, mode),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(List<Plan> plans, BillingMode mode) {
    final selected = _selected ?? plans.first;
    final yearly = plans
        .where((p) => p.period == PlanPeriod.yearly)
        .firstOrNull;
    final monthly = plans
        .where((p) => p.period == PlanPeriod.monthly)
        .firstOrNull;
    final discount = yearly != null && monthly != null
        ? _discountPercent(yearly, monthly)
        : null;
    final dim = context.palette.text2;

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            onPressed: _busy ? null : () => context.pop(PaywallResult.closed),
            tooltip: '닫기',
            icon: Icon(Icons.close_rounded, color: dim),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.xl,
              0,
              AppSpace.xl,
              AppSpace.md,
            ),
            children: [
              const Center(child: LogoTile(size: 64)),
              const SizedBox(height: AppSpace.md),
              Text(
                '칼로리스냅 프리미엄',
                textAlign: TextAlign.center,
                style: AppText.title1.copyWith(
                  color: context.palette.text1,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: AppSpace.xxs),
              Text(
                widget.feature != null
                    ? '${widget.feature!.label}은(는) 프리미엄 기능이에요'
                    : '목표까지 더 빠르고 정확하게',
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(color: dim),
              ),
              if (mode == BillingMode.off) ...[
                const SizedBox(height: AppSpace.md),
                const _Notice(text: '결제는 출시와 함께 열려요.\n지금은 모든 기능을 무료로 쓸 수 있어요.'),
              ],
              if (mode == BillingMode.mock) ...[
                const SizedBox(height: AppSpace.md),
                const _Notice(text: '테스트 결제 모드예요. 실제로 돈이 나가지 않아요.'),
              ],
              const SizedBox(height: AppSpace.xl),
              for (final b in const [
                (Icons.photo_camera_rounded, 'AI 사진 분석 무제한'),
                (Icons.ramen_dining_rounded, '한 상 차림도 음식별로 인식'),
                (Icons.monitor_weight_rounded, '체중 추이와 목표 도달 예측'),
                (Icons.ios_share_rounded, '식단 기록 내보내기'),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: context.palette.brandSubtle,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(b.$1, size: 18, color: AppBrand.orange),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Text(
                        b.$2,
                        style: AppText.body.copyWith(
                          color: context.palette.text1,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpace.md),
              for (final p in plans) ...[
                _PlanCard(
                  plan: p,
                  selected: p == selected,
                  badge: p.period == PlanPeriod.yearly && discount != null
                      ? '$discount% 할인'
                      : null,
                  onTap: () => setState(() => _selected = p),
                ),
                const SizedBox(height: AppSpace.sm),
              ],
              if (selected.trialDays > 0)
                _TrialTimeline(days: selected.trialDays),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.xl,
            AppSpace.xs,
            AppSpace.xl,
            AppSpace.xs,
          ),
          child: SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: mode == BillingMode.off ? null : AppBrand.gradient,
                color: mode == BillingMode.off
                    ? context.palette.surfaceAlt
                    : null,
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              child: FilledButton(
                onPressed: _busy ? null : () => _buy(selected),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  foregroundColor: mode == BillingMode.off ? dim : Colors.white,
                ),
                child: _busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        mode == BillingMode.off
                            ? '출시 준비 중'
                            : selected.trialDays > 0
                            ? '${selected.trialDays}일 무료로 시작하기'
                            : '${selected.periodLabel} 구독 시작하기',
                      ),
              ),
            ),
          ),
        ),
        if (widget.source == PaywallSource.limit &&
            ref.watch(canWatchAdProvider))
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.xl,
              AppSpace.xs,
              AppSpace.xl,
              0,
            ),
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _watchAd,
              icon: const Icon(Icons.play_circle_rounded, size: 20),
              label: Text(
                '광고 보고 1회 더 받기 (오늘 ${ref.watch(adRewardsProvider).today}/$dailyAdRewardLimit)',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppBrand.orange,
                side: const BorderSide(color: AppBrand.orange),
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
        if (widget.source == PaywallSource.limit)
          TextButton.icon(
            onPressed: _busy
                ? null
                : () => context.pop(PaywallResult.manualEntry),
            icon: const Icon(Icons.search_rounded, size: 18),
            label: const Text('AI 없이 사진과 함께 직접 기록하기'),
            style: TextButton.styleFrom(foregroundColor: context.palette.text1),
          ),
        Text(
          selected.trialDays > 0
              ? '체험이 끝나면 ${selected.priceLabel}/${selected.period == PlanPeriod.yearly ? '년' : '월'} 자동 결제돼요. 체험 중 언제든 해지하면 요금이 청구되지 않아요.'
              : '${selected.priceLabel}/${selected.period == PlanPeriod.yearly ? '년' : '월'} · 기간이 끝나기 24시간 전까지 해지하지 않으면 자동 갱신돼요.',
          textAlign: TextAlign.center,
          style: AppText.micro.copyWith(
            fontWeight: FontWeight.w400,
            color: dim,
            height: 1.5,
          ),
        ).paddedH(AppSpace.xl),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: _busy ? null : _restore,
              child: const Text('구매 복원'),
            ),
            Text('·', style: TextStyle(color: dim)),
            TextButton(
              onPressed: () => openTerms(context),
              child: const Text('이용약관'),
            ),
            Text('·', style: TextStyle(color: dim)),
            TextButton(
              onPressed: () => openPrivacy(context),
              child: const Text('개인정보처리방침'),
            ),
          ],
        ),
      ],
    );
  }
}

/// 연간이 월간 12개월 대비 몇 % 싼지. 가격 문자열에서 숫자만 뽑아 계산한다.
int? _discountPercent(Plan yearly, Plan monthly) {
  double? n(String s) => double.tryParse(s.replaceAll(RegExp(r'[^0-9.]'), ''));
  final y = n(yearly.priceLabel), m = n(monthly.priceLabel);
  if (y == null || m == null || m == 0) return null;
  final pct = ((1 - y / (m * 12)) * 100).round();
  return pct > 0 ? pct : null;
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
    this.badge,
  });
  final Plan plan;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final dim = context.palette.text2;
    final sub = [
      ?plan.perMonthLabel,
      if (plan.trialDays > 0) '${plan.trialDays}일 무료 체험',
    ].join(' · ');
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
            color: selected
                ? context.palette.brandSubtle
                : context.palette.card,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: selected ? AppBrand.orange : Colors.transparent,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? AppBrand.orange : dim,
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          plan.periodLabel,
                          style: AppText.headline.copyWith(
                            color: context.palette.text1,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: AppSpace.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppBrand.orange,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              badge!,
                              style: AppText.micro.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (sub.isNotEmpty)
                      Text(sub, style: AppText.caption.copyWith(color: dim)),
                  ],
                ),
              ),
              Text(
                plan.priceLabel,
                style: AppText.numeric(
                  AppText.headline,
                ).copyWith(color: context.palette.text1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 체험 타임라인: 오늘 시작 → 종료 2일 전 알림 → 결제
class _TrialTimeline extends StatelessWidget {
  const _TrialTimeline({required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    final dim = context.palette.text2;
    Widget step(
      IconData icon,
      String title,
      String body, {
      bool last = false,
    }) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(icon, size: 18, color: AppBrand.orange),
            if (!last)
              Container(width: 2, height: 22, color: context.palette.border),
          ],
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.xs),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$title  ',
                    style: AppText.label.copyWith(color: context.palette.text1),
                  ),
                  TextSpan(
                    text: body,
                    style: AppText.caption.copyWith(color: dim),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.xs),
      child: Column(
        children: [
          step(Icons.lock_open_rounded, '오늘', '모든 프리미엄 기능 열림'),
          step(Icons.notifications_active_rounded, '${days - 2}일째', '체험 종료 알림'),
          step(Icons.event_available_rounded, '$days일째', '첫 결제', last: true),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpace.sm),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7E0),
      borderRadius: BorderRadius.circular(AppRadius.control),
      border: Border.all(color: const Color(0xFFFFE29A)),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: AppText.caption.copyWith(color: const Color(0xFF9A6B00)),
    ),
  );
}

class _Error extends StatelessWidget {
  const _Error({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '상품 정보를 불러오지 못했어요',
          style: AppText.body.copyWith(color: context.palette.text1),
        ),
        TextButton(onPressed: onRetry, child: const Text('다시 시도')),
        TextButton(
          onPressed: () => context.pop(PaywallResult.closed),
          child: const Text('닫기'),
        ),
      ],
    ),
  );
}

extension on Widget {
  Widget paddedH(double h) => Padding(
    padding: EdgeInsets.symmetric(horizontal: h),
    child: this,
  );
}
