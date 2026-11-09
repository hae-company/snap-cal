import 'dart:io';

import 'package:flutter/widgets.dart' show Rect;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/meal_type.dart';
import '../models/food_record.dart';

/// 식단 기록을 CSV로. 엑셀에서 한글이 깨지지 않게 BOM을 붙인다.
String buildMealsCsv(List<FoodRecord> records) {
  String cell(Object? v) {
    final s = '${v ?? ''}';
    return s.contains(RegExp(r'[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
  }

  final sorted = [...records]
    ..sort((a, b) {
      final d = a.date.compareTo(b.date);
      return d != 0 ? d : a.createdAt.compareTo(b.createdAt);
    });
  final b = StringBuffer('\uFEFF날짜,끼니,음식,인분,칼로리(kcal),탄수화물(g),단백질(g),지방(g)\n');
  for (final r in sorted) {
    b.writeln(
      [
        r.date,
        MealType.label(r.mealType),
        r.foodName,
        r.servings == r.servings.roundToDouble()
            ? r.servings.toInt()
            : r.servings,
        r.calories,
        r.carbs,
        r.protein,
        r.fat,
      ].map(cell).join(','),
    );
  }
  return b.toString();
}

/// CSV 파일을 만들어 공유 시트를 띄운다.
Future<void> shareMealsCsv(List<FoodRecord> records, {Rect? origin}) async {
  final dir = await getTemporaryDirectory();
  final now = DateTime.now();
  final name =
      'snapcal_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.csv';
  final file = File('${dir.path}/$name');
  await file.writeAsString(buildMealsCsv(records));
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'text/csv')],
      subject: '스냅칼 식단 기록',
      sharePositionOrigin: origin,
    ),
  );
}
