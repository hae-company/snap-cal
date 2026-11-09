/// 기록 출처
abstract final class RecordSource {
  static const ai = 'ai';
  static const db = 'db';
  static const manual = 'manual';
}

/// 음식 한 건의 기록. 칼로리·영양소는 [servings]가 반영된 실제 섭취량이다.
class FoodRecord {
  final int? id;
  final String date; // yyyy-MM-dd
  final String mealType; // breakfast, lunch, dinner, snack
  final String foodName;
  final int calories;
  final int carbs;
  final int protein;
  final int fat;
  final String? imagePath;
  final String? description;
  final DateTime createdAt;

  /// 1인분 대비 배수 (0.5, 1, 1.5 ...). 이전 버전 기록은 1.
  final double servings;

  /// [RecordSource] 값. 이전 버전 기록은 null.
  final String? source;

  FoodRecord({
    this.id,
    required this.date,
    required this.mealType,
    required this.foodName,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
    this.imagePath,
    this.description,
    this.servings = 1,
    this.source,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  FoodRecord copyWith({
    int? id,
    String? date,
    String? mealType,
    String? foodName,
    int? calories,
    int? carbs,
    int? protein,
    int? fat,
    String? imagePath,
    bool clearImagePath = false,
    String? description,
    double? servings,
  }) => FoodRecord(
    id: id ?? this.id,
    date: date ?? this.date,
    mealType: mealType ?? this.mealType,
    foodName: foodName ?? this.foodName,
    calories: calories ?? this.calories,
    carbs: carbs ?? this.carbs,
    protein: protein ?? this.protein,
    fat: fat ?? this.fat,
    imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
    description: description ?? this.description,
    servings: servings ?? this.servings,
    source: source,
    createdAt: createdAt,
  );

  /// 양을 바꾼다. 칼로리·영양소를 1인분 기준으로 되돌린 뒤 새 배수를 곱한다.
  FoodRecord withServings(double next) {
    if (servings <= 0 || next <= 0) return this;
    final ratio = next / servings;
    int scale(int v) => (v * ratio).round();
    return copyWith(
      servings: next,
      calories: scale(calories),
      carbs: scale(carbs),
      protein: scale(protein),
      fat: scale(fat),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date,
    'meal_type': mealType,
    'food_name': foodName,
    'calories': calories,
    'carbs': carbs,
    'protein': protein,
    'fat': fat,
    'image_path': imagePath,
    'description': description,
    'servings': servings,
    'source': source,
    'created_at': createdAt.toIso8601String(),
  };

  factory FoodRecord.fromMap(Map<String, dynamic> map) => FoodRecord(
    id: map['id'] as int?,
    date: map['date'] as String,
    mealType: map['meal_type'] as String,
    foodName: map['food_name'] as String,
    calories: map['calories'] as int,
    carbs: map['carbs'] as int,
    protein: map['protein'] as int,
    fat: map['fat'] as int,
    imagePath: map['image_path'] as String?,
    description: map['description'] as String?,
    servings: (map['servings'] as num?)?.toDouble() ?? 1,
    source: map['source'] as String?,
    createdAt: DateTime.parse(map['created_at'] as String),
  );
}
