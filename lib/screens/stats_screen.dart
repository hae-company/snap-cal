import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/prefs_service.dart';
import '../utils/constants.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, int> _weekCalories = {};
  int _goal = 2000;
  int _totalCarbs = 0, _totalProtein = 0, _totalFat = 0;
  List<Map<String, dynamic>> _topFoods = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _goal = await PrefsService.getDailyGoal();
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final from = DateFormat('yyyy-MM-dd').format(monday);
    final to = DateFormat('yyyy-MM-dd').format(sunday);

    _weekCalories = await DatabaseService.getCaloriesByDateRange(from, to);

    final records = await DatabaseService.getByDateRange(from, to);
    _totalCarbs = records.fold(0, (s, r) => s + r.carbs);
    _totalProtein = records.fold(0, (s, r) => s + r.protein);
    _totalFat = records.fold(0, (s, r) => s + r.fat);

    _topFoods = await DatabaseService.topFoods(5);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final days = ['월', '화', '수', '목', '금', '토', '일'];
    final avg = _weekCalories.isEmpty ? 0 : (_weekCalories.values.reduce((a, b) => a + b) / _weekCalories.length).round();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('이번 주 통계', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Weekly bar chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('주간 칼로리', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 160,
                    child: BarChart(BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (_goal * 1.3).toDouble(),
                      barGroups: List.generate(7, (i) {
                        final day = monday.add(Duration(days: i));
                        final key = DateFormat('yyyy-MM-dd').format(day);
                        final cal = _weekCalories[key] ?? 0;
                        return BarChartGroupData(x: i, barRods: [
                          BarChartRodData(
                            toY: cal.toDouble(),
                            color: cal > _goal ? AppColors.danger : AppColors.primary,
                            width: 20,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ]);
                      }),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) => Text(days[v.toInt()], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        )),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                    )),
                  ),
                  const SizedBox(height: 12),
                  Text('평균 $avg kcal/일', style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Nutrient pie chart
          if (_totalCarbs + _totalProtein + _totalFat > 0)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('영양소 비율', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 160,
                    child: PieChart(PieChartData(
                      sections: [
                        PieChartSectionData(value: _totalCarbs.toDouble(), color: AppColors.carbs, title: '탄수화물', titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold), radius: 60),
                        PieChartSectionData(value: _totalProtein.toDouble(), color: AppColors.protein, title: '단백질', titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold), radius: 60),
                        PieChartSectionData(value: _totalFat.toDouble(), color: AppColors.fat, title: '지방', titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold), radius: 60),
                      ],
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                    )),
                  ),
                ]),
              ),
            ),

          const SizedBox(height: 12),

          // Top foods
          if (_topFoods.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('많이 먹은 음식', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    for (var i = 0; i < _topFoods.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Text('${i + 1}.', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_topFoods[i]['food_name'] as String)),
                            Text('${_topFoods[i]['count']}회', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
