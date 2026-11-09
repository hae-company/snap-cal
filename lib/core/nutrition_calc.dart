/// 목표 칼로리·탄단지 계산.
///
/// 지금은 기존 앱과 같은 Harris-Benedict 공식을 쓴다.
/// 4단계(온보딩 개편)에서 Mifflin-St Jeor로 바꿀 예정 (설계서 7.7 ⑥).
library;

class ActivityLevel {
  const ActivityLevel(this.label, this.description, this.factor);
  final String label;
  final String description;
  final double factor;

  static const all = [
    ActivityLevel('거의 안 함', '주로 앉아서 생활', 1.2),
    ActivityLevel('가벼운 활동', '주 1~3회 운동', 1.375),
    ActivityLevel('보통 활동', '주 3~5회 운동', 1.55),
    ActivityLevel('활발한 활동', '주 6~7회 운동', 1.725),
  ];
}

class NutritionGoals {
  const NutritionGoals({
    required this.kcal,
    required this.carbsG,
    required this.proteinG,
    required this.fatG,
  });

  final int kcal;
  final int carbsG;
  final int proteinG;
  final int fatG;

  static const defaults = NutritionGoals(
    kcal: 2000,
    carbsG: 250,
    proteinG: 60,
    fatG: 55,
  );

  /// 칼로리를 탄 50% / 단 30% / 지 20%로 나눠 그램으로 바꾼다.
  factory NutritionGoals.fromKcal(int kcal) => NutritionGoals(
    kcal: kcal,
    carbsG: (kcal * 0.5 / 4).round(),
    proteinG: (kcal * 0.3 / 4).round(),
    fatG: (kcal * 0.2 / 9).round(),
  );

  NutritionGoals copyWith({int? kcal, int? carbsG, int? proteinG, int? fatG}) =>
      NutritionGoals(
        kcal: kcal ?? this.kcal,
        carbsG: carbsG ?? this.carbsG,
        proteinG: proteinG ?? this.proteinG,
        fatG: fatG ?? this.fatG,
      );

  @override
  bool operator ==(Object other) =>
      other is NutritionGoals &&
      other.kcal == kcal &&
      other.carbsG == carbsG &&
      other.proteinG == proteinG &&
      other.fatG == fatG;

  @override
  int get hashCode => Object.hash(kcal, carbsG, proteinG, fatG);
}

/// 하루 소비 칼로리(TDEE)
int calcTdee({
  required bool male,
  required int age,
  required double heightCm,
  required double weightKg,
  required int activityIndex,
}) {
  final bmr = male
      ? 88.362 + (13.397 * weightKg) + (4.799 * heightCm) - (5.677 * age)
      : 447.593 + (9.247 * weightKg) + (3.098 * heightCm) - (4.330 * age);
  return (bmr * ActivityLevel.all[activityIndex].factor).round();
}
