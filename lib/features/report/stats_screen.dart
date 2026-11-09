import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/tokens.dart';
import '../../core/date_key.dart';
import '../../data/providers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final goal = ref.watch(goalsProvider).kcal;
    final monday = mondayOf(DateTime.now());
    final range = (
      from: dateKey(monday),
      to: dateKey(monday.add(const Duration(days: 6))),
    );
    final records = ref.watch(mealsInRangeProvider(range)).value ?? const [];
    final top = ref.watch(topFoodsProvider(5)).value ?? const [];

    final byDate = caloriesByDate(records);
    final avg = byDate.isEmpty
        ? 0
        : (byDate.values.reduce((a, b) => a + b) / byDate.length).round();
    final carbs = records.fold(0, (s, r) => s + r.carbs);
    final protein = records.fold(0, (s, r) => s + r.protein);
    final fat = records.fold(0, (s, r) => s + r.fat);
    final maxDay = byDate.values.fold(goal, (m, v) => v > m ? v : m);

    PieChartSectionData slice(int v, Color c, String title) =>
        PieChartSectionData(
          value: v.toDouble(),
          color: c,
          title: title,
          radius: 60,
          titleStyle: AppText.micro.copyWith(
            fontSize: 10,
            color: Colors.white,
            fontFamily: 'Pretendard',
          ),
        );

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpace.md),
        children: [
          const Text('이번 주 통계', style: AppText.title1),
          const SizedBox(height: AppSpace.md),
          _Section(
            title: '주간 칼로리',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 160,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxDay * 1.3,
                      barGroups: List.generate(7, (i) {
                        final kcal =
                            byDate[dateKey(monday.add(Duration(days: i)))] ?? 0;
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: kcal.toDouble(),
                              color: kcal > goal ? p.over : p.brand,
                              width: 20,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ],
                        );
                      }),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) => Text(
                              _weekdays[v.toInt()],
                              style: AppText.caption.copyWith(color: p.text2),
                            ),
                          ),
                        ),
                        leftTitles: const AxisTitles(),
                        topTitles: const AxisTitles(),
                        rightTitles: const AxisTitles(),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(enabled: false),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  '평균 $avg kcal/일',
                  style: AppText.body.copyWith(color: p.text2),
                ),
              ],
            ),
          ),
          if (carbs + protein + fat > 0) ...[
            const SizedBox(height: AppSpace.sm),
            _Section(
              title: '영양소 비율',
              child: SizedBox(
                height: 160,
                child: PieChart(
                  PieChartData(
                    sections: [
                      slice(carbs, p.carbs, '탄수화물'),
                      slice(protein, p.protein, '단백질'),
                      slice(fat, p.fat, '지방'),
                    ],
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                  ),
                ),
              ),
            ),
          ],
          if (top.isNotEmpty) ...[
            const SizedBox(height: AppSpace.sm),
            _Section(
              title: '많이 먹은 음식',
              child: Column(
                children: [
                  for (var i = 0; i < top.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Text(
                            '${i + 1}.',
                            style: AppText.label.copyWith(color: p.brand),
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Expanded(child: Text(top[i].$1, style: AppText.body)),
                          Text(
                            '${top[i].$2}회',
                            style: AppText.caption.copyWith(color: p.text2),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppText.headline.copyWith(fontSize: 16)),
            const SizedBox(height: AppSpace.md),
            child,
          ],
        ),
      ),
    );
  }
}
