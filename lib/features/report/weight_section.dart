import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/tokens.dart';
import '../../core/date_key.dart';
import '../../data/providers.dart';
import '../../shared/widgets/input_dialog.dart';

/// 체중 추이 + 오늘 체중 기록
class WeightSection extends ConsumerWidget {
  const WeightSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final all = ref.watch(weightsProvider);
    final target = ref.watch(targetWeightProvider);
    final entries = all.length > 30 ? all.sublist(all.length - 30) : all;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: Text('체중', style: AppText.headline)),
                TextButton.icon(
                  onPressed: () => showWeightDialog(context, ref),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('오늘 체중 기록'),
                ),
              ],
            ),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                child: Center(
                  child: Text(
                    '체중을 기록하면 변화를 그래프로 보여드려요',
                    style: AppText.caption.copyWith(color: p.text3),
                  ),
                ),
              )
            else ...[
              _Summary(first: all.first.$2, last: all.last.$2, target: target),
              const SizedBox(height: AppSpace.md),
              if (entries.length >= 2)
                SizedBox(
                  height: 140,
                  child: _Chart(entries: entries, target: target),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.first,
    required this.last,
    required this.target,
  });
  final double first;
  final double last;
  final double? target;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final diff = last - first;
    final toGo = target == null ? null : last - target!;

    String kg(double v) => v.toStringAsFixed(1);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(kg(last), style: AppText.display.copyWith(fontSize: 32)),
        Padding(
          padding: const EdgeInsets.only(bottom: 4, left: 4),
          child: Text('kg', style: AppText.caption.copyWith(color: p.text2)),
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (diff != 0)
              Text(
                '처음보다 ${diff > 0 ? '+' : ''}${kg(diff)}kg',
                style: AppText.label.copyWith(
                  color: diff < 0 ? p.brand : p.text2,
                ),
              ),
            if (toGo != null)
              Text(
                toGo.abs() < 0.05
                    ? '목표 달성! 🎉'
                    : '목표 ${kg(target!)}kg까지 ${kg(toGo.abs())}kg',
                style: AppText.caption.copyWith(color: p.text2),
              ),
          ],
        ),
      ],
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.entries, required this.target});
  final List<(String, double)> entries;
  final double? target;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final values = [for (final e in entries) e.$2, ?target];
    // 축 눈금이 겹치지 않게 범위를 눈금 간격의 배수로 맞춘다
    final lo = values.reduce((a, b) => a < b ? a : b) - 1;
    final hi = values.reduce((a, b) => a > b ? a : b) + 1;
    final step = ((hi - lo) / 3).ceilToDouble().clamp(1.0, 50.0);
    final minY = (lo / step).floorToDouble() * step;
    final maxY = (hi / step).ceilToDouble() * step;

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (final (i, e) in entries.indexed) FlSpot(i.toDouble(), e.$2),
            ],
            isCurved: true,
            curveSmoothness: 0.25,
            color: p.brand,
            barWidth: 3,
            dotData: FlDotData(
              getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                radius: 3,
                color: p.surface,
                strokeWidth: 2,
                strokeColor: p.brand,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [p.brand.withAlpha(60), p.brand.withAlpha(0)],
              ),
            ),
          ),
        ],
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            if (target != null)
              HorizontalLine(
                y: target!,
                color: p.text3,
                strokeWidth: 1.5,
                dashArray: [4, 4],
              ),
          ],
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: step,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(0),
                style: AppText.micro.copyWith(color: p.text3),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: (entries.length / 4).ceilToDouble().clamp(1, 30),
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= entries.length) {
                  return const SizedBox.shrink();
                }
                final d = DateTime.parse(entries[i].$1);
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${d.month}.${d.day}',
                    style: AppText.micro.copyWith(color: p.text3),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: p.border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
      ),
    );
  }
}

/// 오늘 체중 입력
Future<void> showWeightDialog(BuildContext context, WidgetRef ref) async {
  final weights = ref.read(weightsProvider);
  final kg = await showNumberDialog(
    context,
    title: '오늘 체중',
    initial: weights.isEmpty ? null : weights.last.$2,
    suffix: 'kg',
    decimal: true,
    confirmLabel: '저장',
  );
  if (kg == null || kg < 20 || kg > 300) return;
  await ref
      .read(weightsProvider.notifier)
      .record(dateKey(DateTime.now()), kg.toDouble());
}
