import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../app/theme/tokens.dart';
import '../../core/date_key.dart';
import '../../data/providers.dart';
import 'day_detail_sheet.dart';

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
    final goal = ref.watch(goalsProvider).kcal;
    final monthCalories =
        ref
            .watch(
              monthCaloriesProvider((
                year: _focused.year,
                month: _focused.month,
              )),
            )
            .value ??
        const {};

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.screen,
              AppSpace.md,
              AppSpace.screen,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'SnapCal',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.title1.copyWith(
                      color: p.brand,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_left, color: p.text2),
                  tooltip: '이전 달',
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  DateFormat('yyyy.MM').format(_focused),
                  style: AppText.numeric(AppText.headline),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: p.text2),
                  tooltip: '다음 달',
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),
          TableCalendar<void>(
            locale: 'ko_KR',
            firstDay: DateTime(2020),
            lastDay: DateTime(2035),
            focusedDay: _focused,
            selectedDayPredicate: (d) => isSameDay(d, _selected),
            onDaySelected: (sel, foc) {
              setState(() {
                _selected = sel;
                _focused = foc;
              });
              showDayDetailSheet(context, sel);
            },
            onPageChanged: (foc) => setState(() => _focused = foc),
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {CalendarFormat.month: '월'},
            headerVisible: false,
            daysOfWeekHeight: 32,
            rowHeight: 60,
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: AppText.caption.copyWith(color: p.text2),
              weekendStyle: AppText.caption.copyWith(color: p.text3),
            ),
            calendarStyle: const CalendarStyle(outsideDaysVisible: false),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (_, day, _) => _DayCell(
                day: day,
                kcal: monthCalories[dateKey(day)],
                goal: goal,
              ),
              todayBuilder: (_, day, _) => _DayCell(
                day: day,
                kcal: monthCalories[dateKey(day)],
                goal: goal,
                isToday: true,
              ),
              selectedBuilder: (_, day, _) => _DayCell(
                day: day,
                kcal: monthCalories[dateKey(day)],
                goal: goal,
                isSelected: true,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app, size: 28, color: p.text3),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    '날짜를 탭하면 상세 기록을 볼 수 있어요',
                    style: AppText.label.copyWith(
                      fontWeight: FontWeight.w400,
                      color: p.text3,
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

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.kcal,
    required this.goal,
    this.isToday = false,
    this.isSelected = false,
  });

  final DateTime day;
  final int? kcal;
  final int goal;
  final bool isToday;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final over = kcal != null && kcal! > goal;

    final Color? fill = isSelected
        ? p.brand
        : isToday
        ? p.brandSubtle
        : kcal != null
        ? (over ? p.over.withAlpha(28) : p.brand.withAlpha(22))
        : null;

    // 원 크기를 고정한다. 내용 크기에 맞추면 칼로리가 없는 날은 원이 숫자만큼 작아진다.
    return Center(
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: AppText.numeric(AppText.label).copyWith(
                color: isSelected ? p.onBrand : p.text1,
                fontWeight: isSelected || isToday
                    ? FontWeight.w700
                    : FontWeight.w400,
              ),
            ),
            if (kcal != null)
              Text(
                '$kcal',
                style: AppText.numeric(AppText.micro).copyWith(
                  fontSize: 8,
                  color: isSelected
                      ? p.onBrand.withAlpha(190)
                      : (over ? p.over : p.brand),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
