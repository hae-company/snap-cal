import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/food_record.dart';
import '../services/database_service.dart';
import '../services/prefs_service.dart';
import '../utils/constants.dart';
import '../widgets/meal_card.dart';
import '../widgets/calorie_progress.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();
  List<FoodRecord> _records = [];
  Map<String, int> _monthCalories = {};
  int _goal = 2000;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _goal = await PrefsService.getDailyGoal();
    final dateStr = DateFormat('yyyy-MM-dd').format(_selected);
    final records = await DatabaseService.getByDate(dateStr);

    final firstDay = DateTime(_focused.year, _focused.month, 1);
    final lastDay = DateTime(_focused.year, _focused.month + 1, 0);
    final calories = await DatabaseService.getCaloriesByDateRange(
      DateFormat('yyyy-MM-dd').format(firstDay),
      DateFormat('yyyy-MM-dd').format(lastDay),
    );

    setState(() {
      _records = records;
      _monthCalories = calories;
    });
  }

  int get _todayTotal => _records.fold(0, (sum, r) => sum + r.calories);

  List<FoodRecord> _mealRecords(String type) =>
      _records.where((r) => r.mealType == type).toList();

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('M월 d일 EEEE', 'ko').format(_selected);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
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
                      _load();
                    },
                  ),
                  Text(DateFormat('yyyy.MM').format(_focused), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                    onPressed: () {
                      setState(() => _focused = DateTime(_focused.year, _focused.month + 1));
                      _load();
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
              onDaySelected: (sel, foc) {
                setState(() { _selected = sel; _focused = foc; });
                _load();
              },
              onPageChanged: (foc) {
                _focused = foc;
                _load();
              },
              calendarFormat: CalendarFormat.month,
              headerVisible: false,
              daysOfWeekHeight: 32,
              rowHeight: 56,
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

            const SizedBox(height: 8),

            // Today summary
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dateStr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      CalorieProgress(current: _todayTotal, goal: _goal),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Meals
            for (final type in [MealType.breakfast, MealType.lunch, MealType.dinner, MealType.snack])
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: MealCard(
                  mealType: type,
                  records: _mealRecords(type),
                  onDelete: (id) async {
                    await DatabaseService.delete(id);
                    _load();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _dayCell(DateTime day, bool isToday, bool isSelected) {
    final key = DateFormat('yyyy-MM-dd').format(day);
    final cal = _monthCalories[key];

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : isToday ? AppColors.primaryLight : null,
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
                color: isSelected ? Colors.white70 : AppColors.textHint,
              ),
            ),
        ],
      ),
    );
  }
}
