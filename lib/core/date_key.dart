import 'package:intl/intl.dart';

final _fmt = DateFormat('yyyy-MM-dd');

/// 기록의 날짜 키 (`yyyy-MM-dd`, 사용자 현지 날짜)
String dateKey(DateTime d) => _fmt.format(d);

/// 해당 날짜가 속한 주의 월요일
DateTime mondayOf(DateTime d) {
  final day = DateTime(d.year, d.month, d.day);
  return day.subtract(Duration(days: day.weekday - 1));
}
