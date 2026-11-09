/// 끼니 종류. 저장 값은 문자열(`breakfast` 등)을 그대로 쓴다.
abstract final class MealType {
  static const breakfast = 'breakfast';
  static const lunch = 'lunch';
  static const dinner = 'dinner';
  static const snack = 'snack';

  static const all = [breakfast, lunch, dinner, snack];

  static String label(String type) => switch (type) {
    breakfast => '아침',
    lunch => '점심',
    dinner => '저녁',
    snack => '간식',
    _ => '',
  };

  static String emoji(String type) => switch (type) {
    breakfast => '🌅',
    lunch => '☀️',
    dinner => '🌙',
    snack => '🍪',
    _ => '',
  };

  /// 현재 시각과 끼니 시간대로 끼니를 고른다. 어느 시간대에도 안 맞으면 간식.
  static String detect(DateTime now, Map<String, List<int>> mealTimes) {
    final hour = now.hour;
    for (final type in [breakfast, lunch, dinner]) {
      final range = mealTimes[type];
      if (range != null && hour >= range[0] && hour < range[1]) return type;
    }
    return snack;
  }
}
