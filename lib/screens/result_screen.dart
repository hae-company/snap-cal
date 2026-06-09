import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/analysis_result.dart';
import '../models/food_record.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../widgets/nutrient_bar.dart';

class ResultScreen extends StatelessWidget {
  final AnalysisResult result;
  final String imagePath;

  const ResultScreen({super.key, required this.result, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI 분석 결과')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(File(imagePath), height: 220, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 20),

          // Food name + calories
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(result.foodName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('약 ${result.calories} kcal', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  const SizedBox(height: 4),
                  _confidenceBadge(),
                  if (result.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(result.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Nutrients
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('영양성분', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  NutrientBar(label: '탄수화물', value: result.carbs, max: 150, color: AppColors.carbs, unit: 'g'),
                  const SizedBox(height: 12),
                  NutrientBar(label: '단백질', value: result.protein, max: 80, color: AppColors.protein, unit: 'g'),
                  const SizedBox(height: 12),
                  NutrientBar(label: '지방', value: result.fat, max: 70, color: AppColors.fat, unit: 'g'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Meal type selector
          const Text('어떤 식사로 기록할까요?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [MealType.breakfast, MealType.lunch, MealType.dinner, MealType.snack]
                .map((type) => _mealButton(context, type))
                .toList(),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _confidenceBadge() {
    final color = result.confidence == 'high' ? AppColors.primary
        : result.confidence == 'medium' ? Colors.orange
        : AppColors.danger;
    final label = result.confidence == 'high' ? '높음'
        : result.confidence == 'medium' ? '보통'
        : '낮음';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Text('신뢰도: $label', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _mealButton(BuildContext context, String type) {
    return InkWell(
      onTap: () => _save(context, type),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(MealType.emoji(type), style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(MealType.label(type), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context, String mealType) async {
    final record = FoodRecord(
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      mealType: mealType,
      foodName: result.foodName,
      calories: result.calories,
      carbs: result.carbs,
      protein: result.protein,
      fat: result.fat,
      imagePath: imagePath,
      description: result.description,
    );
    await DatabaseService.insert(record);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${MealType.emoji(mealType)} ${MealType.label(mealType)}에 기록했어요!')),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
