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
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

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
    createdAt: DateTime.parse(map['created_at'] as String),
  );
}
