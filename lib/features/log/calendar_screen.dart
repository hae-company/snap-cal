import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../app/theme/tokens.dart';
import '../../core/date_key.dart';
import '../../core/meal_type.dart';
import '../../data/providers.dart';
import '../../shared/widgets/calorie_ring.dart';
import '../../shared/widgets/macro_summary.dart';
import '../../shared/widgets/meal_section.dart';

/// 목표 대비 하루 상태 (설계서 7.2 캘린더 날짜 색)
enum DayStatus { none, under, onTrack, over }

DayStatus dayStatus(int? kcal, int goal) {
  if (kcal == null || kcal == 0 || goal <= 0) return DayStatus.none;
  final r = kcal / goal;
  if (r > 1.1) return DayStatus.over;
  if (r >= 0.9) return DayStatus.onTrack;
  return DayStatus.under;
}

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();

  void _changeMonth(int delta) => setState(
    () => _focused = DateTime(_focused.year, _focused.month + delta),
  );

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final goals = ref.watch(goalsProvider);
    final month =
        ref
            .watch(
              monthCaloriesProvider((
                year: _focused.year,
                month: _focused.month,
              )),
            )
            .value ??
        const {};
    final records =
        ref.watch(mealsByDateProvider(dateKey(_selected))).value ?? const [];

    final total = records.fold(0, (s, r) => s + r.calories);
    final carbs = records.fold(0, (s, r) => s + r.carbs);
    final protein = records.fold(0, (s, r) => s + r.protein);
    final fat = records.fold(0, (s, r) => s + r.fat);
    final status = dayStatus(total, goals.kcal);

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
          Row(
            children: [
              const Expanded(child: Text('기록', style: AppText.title1)),
              _MonthButton(
                icon: Icons.chevron_left_rounded,
                tooltip: '이전 달',
                onTap: () => _changeMonth(-1),
              ),
              SizedBox(
                width: 88,
                child: Text(
                  DateFormat('yyyy.MM').format(_focused),
                  textAlign: TextAlign.center,
                  style: AppText.numeric(AppText.headline),
                ),
              ),
              _MonthButton(
                icon: Icons.chevron_right_rounded,
                tooltip: '다음 달',
                onTap: () => _changeMonth(1),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.xs,
                AppSpace.sm,
                AppSpace.xs,
                AppSpace.sm,
              ),
              child: Column(
                children: [
                  TableCalendar<void>(
                    locale: 'ko_KR',
                    firstDay: DateTime(2020),
                    lastDay: DateTime(2035),
                    focusedDay: _focused,
                    selectedDayPredicate: (d) => isSameDay(d, _selected),
                    onDaySelected: (sel, foc) => setState(() {
                      _selected = sel;
                      _focused = foc;
                    }),
                    onPageChanged: (foc) => setState(() => _focused = foc),
                    calendarFormat: CalendarFormat.month,
                    availableCalendarFormats: const {CalendarFormat.month: '월'},
                    headerVisible: false,
                    sixWeekMonthsEnforced: false,
                    daysOfWeekHeight: 28,
                    rowHeight: 52,
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: AppText.micro.copyWith(color: p.text3),
                      weekendStyle: AppText.micro.copyWith(color: p.text3),
                    ),
                    calendarStyle: const CalendarStyle(
                      outsideDaysVisible: false,
                    ),
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (_, day, _) => DayCell(
                        day: day,
                        status: dayStatus(month[dateKey(day)], goals.kcal),
                      ),
                      todayBuilder: (_, day, _) => DayCell(
                        day: day,
                        status: dayStatus(month[dateKey(day)], goals.kcal),
                        isToday: true,
                      ),
                      selectedBuilder: (_, day, _) => DayCell(
                        day: day,
                        status: dayStatus(month[dateKey(day)], goals.kcal),
                        isToday: isSameDay(day, DateTime.now()),
                        isSelected: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  const _Legend(),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpace.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  DateFormat('M월 d일 EEEE', 'ko').format(_selected),
                  style: AppText.title2.copyWith(fontSize: 18),
                ),
              ),
              if (status != DayStatus.none) _StatusPill(status: status),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          if (records.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.xxl),
                child: Column(
                  children: [
                    Icon(Icons.event_note_rounded, size: 32, color: p.text3),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      '이 날은 기록이 없어요',
                      style: AppText.body.copyWith(color: p.text3),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.lg),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatKcal(total),
                          style: AppText.display.copyWith(fontSize: 32),
                        ),
                        const SizedBox(width: AppSpace.xxs),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '/ ${formatKcal(goals.kcal)} kcal',
                            style: AppText.caption.copyWith(color: p.text2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.md),
                    MacroSummary(
                      carbs: carbs,
                      protein: protein,
                      fat: fat,
                      goals: goals,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            for (final type in MealType.all)
              if (records.any((r) => r.mealType == type)) ...[
                MealSection(
                  mealType: type,
                  records: records.where((r) => r.mealType == type).toList(),
                  onDelete: (r) => ref.read(mealActionsProvider).delete(r.id!),
                ),
                const SizedBox(height: AppSpace.sm),
              ],
          ],
        ],
      ),
    );
  }
}

class DayCell extends StatelessWidget {
  const DayCell({
    super.key,
    required this.day,
    required this.status,
    this.isToday = false,
    this.isSelected = false,
  });

  final DateTime day;
  final DayStatus status;
  final bool isToday;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    final (Color? fill, Color text) = switch (status) {
      DayStatus.onTrack => (p.brand, p.onBrand),
      DayStatus.over => (p.over, Colors.white),
      DayStatus.under => (p.brandSubtle, p.brandPressed),
      DayStatus.none => (null, p.text1),
    };

    return Center(
      child: AnimatedContainer(
        duration: AppMotion.fast,
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: p.text1, width: 2)
              : isToday && fill == null
              ? Border.all(color: p.brand, width: 1.5)
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: AppText.numeric(AppText.label).copyWith(
            color: text,
            fontWeight: isSelected || isToday || fill != null
                ? FontWeight.w700
                : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget item(Color c, String label, {Color? border}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
            border: border == null ? null : Border.all(color: border),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppText.micro.copyWith(
            fontWeight: FontWeight.w500,
            color: p.text2,
          ),
        ),
      ],
    );
    return Wrap(
      spacing: AppSpace.md,
      alignment: WrapAlignment.center,
      children: [
        item(p.brand, '목표 달성'),
        item(p.brandSubtle, '부족', border: p.brand.withAlpha(120)),
        item(p.over, '초과'),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final DayStatus status;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (String label, Color c) = switch (status) {
      DayStatus.onTrack => ('목표 달성', p.brand),
      DayStatus.over => ('목표 초과', p.over),
      _ => ('목표보다 적게', p.text2),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withAlpha(30),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(label, style: AppText.micro.copyWith(fontSize: 12, color: c)),
    );
  }
}

class _MonthButton extends StatelessWidget {
  const _MonthButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return IconButton.filledTonal(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: p.surface,
        foregroundColor: p.text1,
        side: BorderSide(color: p.border),
      ),
    );
  }
}
