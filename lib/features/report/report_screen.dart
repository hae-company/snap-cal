import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme/tokens.dart';
import '../../core/date_key.dart';
import '../../data/providers.dart';
import '../../shared/widgets/calorie_ring.dart';

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final goal = ref.watch(goalsProvider).kcal;
    final now = DateTime.now();
    final monday = mondayOf(now);
    final sunday = monday.add(const Duration(days: 6));
    final range = (from: dateKey(monday), to: dateKey(sunday));
    final records = ref.watch(mealsInRangeProvider(range)).value ?? const [];
    final top = ref.watch(topFoodsProvider(5)).value ?? const [];

    final byDate = caloriesByDate(records);
    final loggedDays = byDate.length;
    final avg = loggedDays == 0
        ? 0
        : (byDate.values.reduce((a, b) => a + b) / loggedDays).round();
    final onTrack = byDate.values
        .where((v) => v >= goal * 0.9 && v <= goal * 1.1)
        .length;
    final carbs = records.fold(0, (s, r) => s + r.carbs);
    final protein = records.fold(0, (s, r) => s + r.protein);
    final fat = records.fold(0, (s, r) => s + r.fat);
    final maxDay = byDate.values.fold(goal, (m, v) => v > m ? v : m);
    final todayIndex = now.weekday - 1;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.screen,
          AppSpace.sm,
          AppSpace.screen,
          120,
        ),
        children: [
          const Text('리포트', style: AppText.title1),
          const SizedBox(height: 2),
          Text(
            '이번 주 · ${DateFormat('M.d').format(monday)} – ${DateFormat('M.d').format(sunday)}',
            style: AppText.caption.copyWith(color: p.text2),
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              _StatTile(label: '하루 평균', value: formatKcal(avg), unit: 'kcal'),
              const SizedBox(width: AppSpace.xs),
              _StatTile(label: '기록한 날', value: '$loggedDays', unit: '/ 7일'),
              const SizedBox(width: AppSpace.xs),
              _StatTile(
                label: '목표 달성',
                value: '$onTrack',
                unit: '일',
                accent: p.brand,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          _Section(
            title: '일별 칼로리',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 14, height: 2, color: p.text3),
                const SizedBox(width: 4),
                Text(
                  '목표 ${formatKcal(goal)}',
                  style: AppText.micro.copyWith(color: p.text3),
                ),
              ],
            ),
            child: SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxDay * 1.2,
                  barGroups: List.generate(7, (i) {
                    final kcal =
                        byDate[dateKey(monday.add(Duration(days: i)))] ?? 0;
                    final over = kcal > goal * 1.1;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: kcal.toDouble(),
                          width: 22,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          gradient: over
                              ? LinearGradient(colors: [p.over, p.over])
                              : LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    p.brand,
                                    i == todayIndex ? AppBrand.neon : p.brand,
                                  ],
                                ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxDay * 1.2,
                            color: p.surfaceAlt,
                          ),
                        ),
                      ],
                    );
                  }),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: goal.toDouble(),
                        color: p.text3,
                        strokeWidth: 1.5,
                        dashArray: [4, 4],
                      ),
                    ],
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (v, _) => Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _weekdays[v.toInt()],
                            style: AppText.micro.copyWith(
                              color: v.toInt() == todayIndex
                                  ? p.text1
                                  : p.text3,
                              fontWeight: v.toInt() == todayIndex
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
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
          ),
          const SizedBox(height: AppSpace.sm),
          _Section(
            title: '탄단지 비율',
            child: carbs + protein + fat == 0
                ? const _Empty(text: '이번 주 기록이 쌓이면 보여드릴게요')
                : _MacroDonut(carbs: carbs, protein: protein, fat: fat),
          ),
          const SizedBox(height: AppSpace.sm),
          _Section(
            title: '자주 먹은 음식',
            child: top.isEmpty
                ? const _Empty(text: '아직 기록이 없어요')
                : Column(
                    children: [
                      for (var i = 0; i < top.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: i == 0 ? p.brand : p.surfaceAlt,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${i + 1}',
                                  style: AppText.micro.copyWith(
                                    fontSize: 12,
                                    color: i == 0 ? p.onBrand : p.text2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpace.sm),
                              Expanded(
                                child: Text(
                                  top[i].$1,
                                  style: AppText.body,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${top[i].$2}회',
                                style: AppText.numeric(
                                  AppText.caption,
                                ).copyWith(color: p.text2),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _MacroDonut extends StatelessWidget {
  const _MacroDonut({
    required this.carbs,
    required this.protein,
    required this.fat,
  });
  final int carbs;
  final int protein;
  final int fat;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // 칼로리 기준 비율 (탄·단 4kcal/g, 지 9kcal/g)
    final kc = carbs * 4, kp = protein * 4, kf = fat * 9;
    final total = kc + kp + kf;
    int pct(int v) => total == 0 ? 0 : (v * 100 / total).round();

    PieChartSectionData slice(int v, Color c) => PieChartSectionData(
      value: v.toDouble(),
      color: c,
      showTitle: false,
      radius: 18,
    );

    Widget legend(String label, int grams, int percent, Color c) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: AppSpace.xs),
          Expanded(
            child: Text(
              label,
              style: AppText.label.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Text('$percent%', style: AppText.numeric(AppText.label)),
          SizedBox(
            width: 56,
            child: Text(
              '${grams}g',
              textAlign: TextAlign.right,
              style: AppText.numeric(AppText.caption).copyWith(color: p.text3),
            ),
          ),
        ],
      ),
    );

    return Row(
      children: [
        SizedBox.square(
          dimension: 120,
          child: PieChart(
            PieChartData(
              sections: [
                slice(kc, p.carbs),
                slice(kp, p.protein),
                slice(kf, p.fat),
              ],
              sectionsSpace: 3,
              centerSpaceRadius: 38,
              startDegreeOffset: -90,
            ),
          ),
        ),
        const SizedBox(width: AppSpace.lg),
        Expanded(
          child: Column(
            children: [
              legend('탄수화물', carbs, pct(kc), p.carbs),
              legend('단백질', protein, pct(kp), p.protein),
              legend('지방', fat, pct(kf), p.fat),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.unit,
    this.accent,
  });
  final String label;
  final String value;
  final String unit;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppText.caption.copyWith(color: p.text2)),
              const SizedBox(height: AppSpace.xxs),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: AppText.numeric(
                          AppText.title2,
                        ).copyWith(color: accent ?? p.text1),
                      ),
                      TextSpan(
                        text: ' $unit',
                        style: AppText.micro.copyWith(color: p.text3),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: AppText.headline)),
                ?trailing,
              ],
            ),
            const SizedBox(height: AppSpace.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
    child: Center(
      child: Text(
        text,
        style: AppText.caption.copyWith(color: context.palette.text3),
      ),
    ),
  );
}
