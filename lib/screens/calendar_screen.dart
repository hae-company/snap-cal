import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/food_record.dart';
import '../services/database_service.dart';
import '../services/prefs_service.dart';
import '../utils/constants.dart';
import '../widgets/meal_card.dart';
import '../widgets/calorie_progress.dart';
import '../widgets/nutrient_bar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();
  Map<String, int> _monthCalories = {};
  int _goal = 2000;

  @override
  void initState() {
    super.initState();
    _loadMonth();
  }

  Future<void> _loadMonth() async {
    _goal = await PrefsService.getDailyGoal();
    final firstDay = DateTime(_focused.year, _focused.month, 1);
    final lastDay = DateTime(_focused.year, _focused.month + 1, 0);
    final calories = await DatabaseService.getCaloriesByDateRange(
      DateFormat('yyyy-MM-dd').format(firstDay),
      DateFormat('yyyy-MM-dd').format(lastDay),
    );
    setState(() => _monthCalories = calories);
  }

  void _onDaySelected(DateTime sel, DateTime foc) {
    setState(() { _selected = sel; _focused = foc; });
    _showDayDetail(sel);
  }

  Future<void> _showDayDetail(DateTime day) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    final records = await DatabaseService.getByDate(dateStr);
    final total = records.fold(0, (s, r) => s + r.calories);
    final totalCarbs = records.fold(0, (s, r) => s + r.carbs);
    final totalProtein = records.fold(0, (s, r) => s + r.protein);
    final totalFat = records.fold(0, (s, r) => s + r.fat);
    final displayDate = DateFormat('M월 d일 EEEE', 'ko').format(day);

    List<FoodRecord> mealRecords(String type) =>
        records.where((r) => r.mealType == type).toList();

    if (!mounted) return;
    final ctx = context;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
                ),
              ),

              // Date + Calorie progress
              Text(displayDate, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              CalorieProgress(current: total, goal: _goal),

              const SizedBox(height: 16),

              // 탄단지 게이지
              if (records.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('영양성분', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 14),
                        NutrientBar(label: '탄수화물', value: totalCarbs, max: 300, color: AppColors.carbs, unit: 'g'),
                        const SizedBox(height: 10),
                        NutrientBar(label: '단백질', value: totalProtein, max: 150, color: AppColors.protein, unit: 'g'),
                        const SizedBox(height: 10),
                        NutrientBar(label: '지방', value: totalFat, max: 100, color: AppColors.fat, unit: 'g'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // 식사별 기록
              for (final type in [MealType.breakfast, MealType.lunch, MealType.dinner, MealType.snack])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MealCard(
                    mealType: type,
                    records: mealRecords(type),
                    onDelete: (id) async {
                      await DatabaseService.delete(id);
                      Navigator.pop(sheetCtx);
                      _loadMonth();
                      // 다시 열기
                      Future.delayed(const Duration(milliseconds: 300), () => _showDayDetail(day));
                    },
                  ),
                ),

              if (records.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text('이 날은 기록이 없어요', style: TextStyle(color: AppColors.textHint, fontSize: 15)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                const Text('SnapCal', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: AppColors.textSecondary),
                  onPressed: () {
                    setState(() => _focused = DateTime(_focused.year, _focused.month - 1));
                    _loadMonth();
                  },
                ),
                Text(DateFormat('yyyy.MM').format(_focused), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  onPressed: () {
                    setState(() => _focused = DateTime(_focused.year, _focused.month + 1));
                    _loadMonth();
                  },
                ),
              ],
            ),
          ),

          // Calendar
          TableCalendar(
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            focusedDay: _focused,
            selectedDayPredicate: (d) => isSameDay(d, _selected),
            onDaySelected: _onDaySelected,
            onPageChanged: (foc) {
              _focused = foc;
              _loadMonth();
            },
            calendarFormat: CalendarFormat.month,
            headerVisible: false,
            daysOfWeekHeight: 32,
            rowHeight: 60,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              outsideDaysVisible: false,
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (ctx, day, foc) => _dayCell(day, false, false),
              todayBuilder: (ctx, day, foc) => _dayCell(day, true, false),
              selectedBuilder: (ctx, day, foc) => _dayCell(day, false, true),
            ),
          ),

          // 오늘 요약 (하단)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.touch_app, size: 28, color: AppColors.textHint),
                    const SizedBox(height: 8),
                    const Text('날짜를 탭하면 상세 기록을 볼 수 있어요', style: TextStyle(color: AppColors.textHint, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayCell(DateTime day, bool isToday, bool isSelected) {
    final key = DateFormat('yyyy-MM-dd').format(day);
    final cal = _monthCalories[key];
    final overGoal = cal != null && cal > _goal;

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary
            : isToday
                ? AppColors.primaryLight
                : cal != null
                    ? (overGoal ? AppColors.danger.withAlpha(20) : AppColors.primary.withAlpha(15))
                    : null,
        shape: BoxShape.circle,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 14,
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (cal != null)
            Text(
              '$cal',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white70
                    : overGoal
                        ? AppColors.danger
                        : AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }
}
