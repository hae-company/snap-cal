import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme/tokens.dart';
import '../../data/providers.dart';

final _ml = NumberFormat.decimalPattern('ko');

/// 물 섭취. 한 번 누를 때 한 잔(250ml)씩.
class WaterCard extends ConsumerWidget {
  const WaterCard({super.key, required this.date});
  final String date;

  static const cup = 250;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final ml = ref.watch(waterProvider(date));
    final goal = ref.watch(waterGoalProvider);
    final cups = (goal / cup).ceil().clamp(1, 16);
    final filled = ml ~/ cup;
    final water = p.carbs;

    void add(int delta) {
      HapticFeedback.lightImpact();
      ref.read(waterProvider(date).notifier).add(delta);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.md,
          AppSpace.md,
          AppSpace.xs,
          AppSpace.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.water_drop_rounded, size: 18, color: water),
                      const SizedBox(width: 4),
                      Text('물', style: AppText.headline),
                      const SizedBox(width: AppSpace.xs),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: _ml.format(ml),
                              style: AppText.numeric(AppText.label),
                            ),
                            TextSpan(
                              text: ' / ${_ml.format(goal)}ml',
                              style: AppText.micro.copyWith(color: p.text3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (var i = 0; i < cups; i++)
                        AnimatedContainer(
                          duration: AppMotion.fast,
                          width: 18,
                          height: 24,
                          decoration: BoxDecoration(
                            color: i < filled ? water : p.surfaceAlt,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3),
                              bottom: Radius.circular(7),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: ml <= 0 ? null : () => add(-cup),
              tooltip: '한 잔 빼기',
              icon: const Icon(Icons.remove_rounded),
            ),
            IconButton.filled(
              onPressed: () => add(cup),
              tooltip: '물 한 잔 추가',
              icon: const Icon(Icons.add_rounded),
              style: IconButton.styleFrom(
                backgroundColor: water,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
