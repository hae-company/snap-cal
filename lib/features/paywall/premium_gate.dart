import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/tokens.dart';
import '../../data/billing/billing_models.dart';
import '../../data/billing/billing_providers.dart';
import 'paywall_screen.dart';

/// 페이월을 연다.
Future<PaywallResult> openPaywall(
  BuildContext context, {
  PaywallSource source = PaywallSource.my,
  PremiumFeature? feature,
}) async {
  final result = await context.push<PaywallResult>(
    Uri(
      path: Routes.paywall,
      queryParameters: {'source': source.name, 'feature': ?feature?.name},
    ).toString(),
  );
  return result ?? PaywallResult.closed;
}

/// 프리미엄 기능을 쓰기 전에 부른다. 쓸 수 있으면 true (잠금이 없거나, 구독 중이거나, 방금 구독함).
Future<bool> ensurePremium(
  BuildContext context,
  WidgetRef ref,
  PremiumFeature feature,
) async {
  if (ref.read(accessLevelProvider).unlocked) return true;
  final result = await openPaywall(
    context,
    source: PaywallSource.feature,
    feature: feature,
  );
  return result == PaywallResult.subscribed;
}

/// AI 분석 전에 확인한 결과
enum AnalysisGate {
  /// 분석해도 됨 (체험이 남았거나, 잠금이 없거나, 방금 구독함)
  proceed,

  /// AI 없이 사진만 찍고 검색·직접 입력으로 기록하기로 함
  manualEntry,

  /// 그만둠
  stop,
}

/// AI 분석 전에 부른다. 무료 체험을 다 썼으면 페이월을 띄운다.
Future<AnalysisGate> ensureAnalysisQuota(
  BuildContext context,
  WidgetRef ref,
) async {
  final remaining = ref.read(remainingFreeAnalysesProvider);
  if (remaining == null || remaining > 0) return AnalysisGate.proceed;
  return openLimitPaywall(context);
}

/// 무료 분석을 다 쓴 사용자용 페이월 (직접 기록 버튼 포함)
Future<AnalysisGate> openLimitPaywall(BuildContext context) async {
  final result = await openPaywall(
    context,
    source: PaywallSource.limit,
    feature: PremiumFeature.unlimitedAnalysis,
  );
  return switch (result) {
    PaywallResult.subscribed => AnalysisGate.proceed,
    PaywallResult.manualEntry => AnalysisGate.manualEntry,
    PaywallResult.closed => AnalysisGate.stop,
  };
}

/// 잠긴 기능은 흐리게 보여주고 그 위에 "프리미엄으로 보기" 버튼을 띄운다.
class PremiumLock extends ConsumerWidget {
  const PremiumLock({super.key, required this.feature, required this.child});
  final PremiumFeature feature;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(accessLevelProvider).unlocked) return child;
    final p = context.palette;
    return Stack(
      alignment: Alignment.center,
      children: [
        ExcludeSemantics(
          child: IgnorePointer(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: child,
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: () => openPaywall(
            context,
            source: PaywallSource.feature,
            feature: feature,
          ),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 44),
            backgroundColor: p.text1,
            foregroundColor: p.bg,
          ),
          icon: const Icon(Icons.lock_rounded, size: 16),
          label: const Text('프리미엄으로 보기'),
        ),
      ],
    );
  }
}
