import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/tokens.dart';
import '../../data/ads/rewarded_ads.dart';
import '../../data/billing/billing_models.dart';
import '../../data/billing/billing_providers.dart';
import '../../data/billing/billing_service.dart';
import '../../data/providers.dart';
import 'premium_gate.dart';

/// MY의 구독 상태 카드: 상태, 시작/관리 버튼, 구매 복원
class PremiumCard extends ConsumerWidget {
  const PremiumCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final billing = ref.watch(billingServiceProvider);
    final access = ref.watch(accessLevelProvider);
    final entitlement =
        ref.watch(entitlementProvider).value ?? Entitlement.none;
    final remaining = ref.watch(remainingFreeAnalysesProvider);

    final (String title, String body) = switch (access) {
      AccessLevel.open => (
        '프리미엄 (출시 예정)',
        '결제 준비 중이에요. 지금은 모든 기능을 무료로 쓸 수 있어요.',
      ),
      AccessLevel.premium => (
        entitlement.inTrial ? '프리미엄 무료 체험 중' : '프리미엄 이용 중',
        _expiryText(entitlement),
      ),
      AccessLevel.adSupported => (
        '무료로 이용 중',
        'AI 분석 $remaining회 남음 · 광고를 보면 하루 $dailyAdRewardLimit회 더 받을 수 있어요',
      ),
      AccessLevel.free => (
        '무료 이용 중',
        ref.watch(rewardedAdsProvider).mode.enabled
            ? 'AI 분석 $remaining회 남음 · 광고로 하루 $dailyAdRewardLimit회 더 · 프리미엄은 무제한'
            : 'AI 분석 $remaining회 남음 · 프리미엄은 무제한',
      ),
    };

    Future<void> restore() async {
      final e = await ref.read(entitlementProvider.notifier).restore();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.premium ? '구독을 복원했어요' : '복원할 구독이 없어요')),
      );
    }

    Future<void> manage() async {
      final url = entitlement.managementUrl;
      if (url != null &&
          await launchUrl(
            Uri.parse(url),
            mode: LaunchMode.externalApplication,
          )) {
        return;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('휴대폰 설정 > 계정 > 구독에서 관리할 수 있어요')),
        );
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppBrand.gradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    access == AccessLevel.adSupported
                        ? Icons.auto_awesome_rounded
                        : Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppText.headline),
                      Text(
                        body,
                        style: AppText.caption.copyWith(color: p.text2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (access != AccessLevel.adSupported) ...[
              const SizedBox(height: AppSpace.sm),
              Row(
                children: [
                  Expanded(
                    child: access == AccessLevel.premium
                        ? OutlinedButton(
                            onPressed: manage,
                            child: const Text('구독 관리'),
                          )
                        : FilledButton(
                            onPressed: () => openPaywall(context),
                            child: Text(
                              access == AccessLevel.open ? '미리보기' : '프리미엄 시작하기',
                            ),
                          ),
                  ),
                  if (access != AccessLevel.open) ...[
                    const SizedBox(width: AppSpace.xs),
                    TextButton(onPressed: restore, child: const Text('구매 복원')),
                  ],
                ],
              ),
            ],
            // 개발 빌드에서만: 시험용 초기화
            if (billing is MockBillingService ||
                (kDebugMode && access == AccessLevel.adSupported)) ...[
              const SizedBox(height: AppSpace.xs),
              TextButton.icon(
                onPressed: () async {
                  if (billing is MockBillingService) await billing.reset();
                  final repo = ref.read(settingsRepositoryProvider);
                  await repo.setFreeAnalysesUsed(0);
                  await repo.setBonusAnalyses(0);
                  await repo.setAdRewards('', 0);
                  ref.invalidate(freeAnalysesUsedProvider);
                  ref.invalidate(adRewardsProvider);
                },
                icon: const Icon(Icons.restart_alt_rounded, size: 16),
                label: const Text('테스트: 구독·무료·광고 횟수 초기화'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _expiryText(Entitlement e) {
    if (e.expiresAt == null) return '모든 프리미엄 기능을 쓸 수 있어요';
    final d = DateFormat('yyyy.M.d').format(e.expiresAt!.toLocal());
    if (e.inTrial) return '$d에 체험이 끝나요';
    return e.willRenew ? '$d 자동 갱신' : '$d까지 이용 가능 (갱신 안 함)';
  }
}
