import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/tokens.dart';
import '../../data/billing/billing_models.dart';
import '../../data/billing/billing_providers.dart';
import 'paywall_screen.dart';

/// 페이월을 연다. 구독하면 true.
Future<bool> openPaywall(
  BuildContext context, {
  PaywallSource source = PaywallSource.my,
  PremiumFeature? feature,
}) async {
  final ok = await context.push<bool>(
    Uri(
      path: Routes.paywall,
      queryParameters: {'source': source.name, 'feature': ?feature?.name},
    ).toString(),
  );
  return ok == true;
}

/// 프리미엄 기능을 쓰기 전에 부른다. 쓸 수 있으면 true (잠금이 없거나, 구독 중이거나, 방금 구독함).
Future<bool> ensurePremium(
  BuildContext context,
  WidgetRef ref,
  PremiumFeature feature,
) async {
  if (ref.read(accessLevelProvider).unlocked) return true;
  return openPaywall(context, source: PaywallSource.feature, feature: feature);
}

/// AI 분석 전에 부른다. 무료 체험이 남았거나 잠금이 없으면 true.
Future<bool> ensureAnalysisQuota(BuildContext context, WidgetRef ref) async {
  final remaining = ref.read(remainingFreeAnalysesProvider);
  if (remaining == null || remaining > 0) return true;
  return openPaywall(
    context,
    source: PaywallSource.limit,
    feature: PremiumFeature.unlimitedAnalysis,
  );
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
