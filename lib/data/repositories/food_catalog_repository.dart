import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle;

import '../models/food_item.dart';

/// 앱에 내장된 음식 목록 검색.
///
/// 2단계(AI 서버)에서 식약처 식품영양성분 DB를 가공한 목록으로 바꾼다.
class FoodCatalogRepository {
  FoodCatalogRepository(this._bundle);
  final AssetBundle _bundle;

  static const assetPath = 'assets/data/korean_foods.json';

  List<FoodItem>? _cache;

  Future<List<FoodItem>> all() async {
    if (_cache != null) return _cache!;
    final raw =
        jsonDecode(await _bundle.loadString(assetPath)) as Map<String, dynamic>;
    return _cache = [
      for (final f in raw['foods'] as List)
        FoodItem.fromJson(f as Map<String, dynamic>),
    ];
  }

  Future<List<FoodItem>> search(String query, {int limit = 50}) async {
    return searchFoods(await all(), query, limit: limit);
  }
}

/// 이름·별칭으로 찾는다. "ㄱㅊㅉㄱ"처럼 초성만 입력해도 된다.
/// 정확히 같음 → 앞부분 일치 → 포함 순으로 정렬.
List<FoodItem> searchFoods(
  List<FoodItem> foods,
  String query, {
  int limit = 50,
}) {
  final q = _normalize(query);
  if (q.isEmpty) return const [];
  final choseongOnly = q.runes.every(_isCompatConsonant);

  int? score(String text) {
    final t = choseongOnly ? choseong(_normalize(text)) : _normalize(text);
    if (t == q) return 0;
    if (t.startsWith(q)) return 1;
    if (t.contains(q)) return 2;
    return null;
  }

  final ranked = <(int, int, FoodItem)>[];
  for (final f in foods) {
    final scores = [
      score(f.name),
      for (final a in f.aliases) score(a),
    ].whereType<int>();
    if (scores.isEmpty) continue;
    final best = scores.reduce((a, b) => a < b ? a : b);
    ranked.add((best, f.name.length, f));
  }
  ranked.sort(
    (a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2),
  );
  return [for (final r in ranked.take(limit)) r.$3];
}

String _normalize(String s) => s.replaceAll(RegExp(r'\s+'), '').toLowerCase();

const _cho = [
  'ㄱ',
  'ㄲ',
  'ㄴ',
  'ㄷ',
  'ㄸ',
  'ㄹ',
  'ㅁ',
  'ㅂ',
  'ㅃ',
  'ㅅ',
  'ㅆ',
  'ㅇ',
  'ㅈ',
  'ㅉ',
  'ㅊ',
  'ㅋ',
  'ㅌ',
  'ㅍ',
  'ㅎ',
];

bool _isCompatConsonant(int rune) => rune >= 0x3131 && rune <= 0x314E;

/// 한글 음절을 초성으로 바꾼다. 한글이 아닌 글자는 그대로 둔다.
String choseong(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    if (r >= 0xAC00 && r <= 0xD7A3) {
      b.write(_cho[(r - 0xAC00) ~/ 588]);
    } else {
      b.writeCharCode(r);
    }
  }
  return b.toString();
}
