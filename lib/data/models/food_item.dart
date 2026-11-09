/// 음식 목록의 한 항목. 영양소는 1인분([serving]) 기준.
class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.serving,
    required this.grams,
    required this.kcal,
    required this.carbs,
    required this.protein,
    required this.fat,
    this.aliases = const [],
  });

  final String id;
  final String name;
  final String category;
  final String serving;
  final int grams;
  final int kcal;
  final int carbs;
  final int protein;
  final int fat;
  final List<String> aliases;

  factory FoodItem.fromJson(Map<String, dynamic> j) => FoodItem(
    id: j['id'] as String,
    name: j['name'] as String,
    category: j['category'] as String,
    serving: j['serving'] as String,
    grams: j['grams'] as int,
    kcal: j['kcal'] as int,
    carbs: j['carbs'] as int,
    protein: j['protein'] as int,
    fat: j['fat'] as int,
    aliases: [for (final a in j['aliases'] as List? ?? const []) a as String],
  );
}
