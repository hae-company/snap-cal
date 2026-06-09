class AnalysisResult {
  final String foodName;
  final int calories;       // 1인분 칼로리
  final int totalCalories;  // 사진 전체 칼로리
  final String servingInfo; // "약 2~3조각 (1마리 중 1/5)"
  final int carbs;
  final int protein;
  final int fat;
  final String confidence;
  final String description;
  final String? error;

  AnalysisResult({
    required this.foodName,
    required this.calories,
    this.totalCalories = 0,
    this.servingInfo = '',
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.confidence,
    required this.description,
    this.error,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('error')) {
      return AnalysisResult(
        foodName: '', calories: 0, carbs: 0, protein: 0, fat: 0,
        confidence: '', description: '', error: json['error'] as String,
      );
    }
    return AnalysisResult(
      foodName: json['food_name'] as String? ?? '알 수 없는 음식',
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      totalCalories: (json['total_calories'] as num?)?.toInt() ?? 0,
      servingInfo: json['serving_info'] as String? ?? '',
      carbs: (json['carbs'] as num?)?.toInt() ?? 0,
      protein: (json['protein'] as num?)?.toInt() ?? 0,
      fat: (json['fat'] as num?)?.toInt() ?? 0,
      confidence: json['confidence'] as String? ?? 'low',
      description: json['description'] as String? ?? '',
    );
  }

  bool get hasError => error != null;
}
