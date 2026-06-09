import 'dart:io';
import 'package:flutter/material.dart';
import '../models/food_record.dart';
import '../utils/constants.dart';

class MealCard extends StatelessWidget {
  final String mealType;
  final List<FoodRecord> records;
  final Function(int) onDelete;

  const MealCard({super.key, required this.mealType, required this.records, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final total = records.fold(0, (s, r) => s + r.calories);
    final totalCarbs = records.fold(0, (s, r) => s + r.carbs);
    final totalProtein = records.fold(0, (s, r) => s + r.protein);
    final totalFat = records.fold(0, (s, r) => s + r.fat);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(MealType.emoji(mealType), style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(MealType.label(mealType), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                if (total > 0) Text('$total kcal', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),

            if (records.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text('아직 기록이 없어요', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
              ),

            // 탄단지 요약 (기록이 있을 때)
            if (records.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const SizedBox(width: 28),
                  _nutrientChip('탄', totalCarbs, AppColors.carbs),
                  const SizedBox(width: 6),
                  _nutrientChip('단', totalProtein, AppColors.protein),
                  const SizedBox(width: 6),
                  _nutrientChip('지', totalFat, AppColors.fat),
                ],
              ),
            ],

            // 각 음식 기록
            for (final r in records)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 썸네일 (갤러리 이미지 경로)
                    if (r.imagePath != null && File(r.imagePath!).existsSync())
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(r.imagePath!),
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.restaurant, size: 20, color: AppColors.primary),
                      ),
                    const SizedBox(width: 10),

                    // 음식 정보
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.foodName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text(
                            '${r.calories}kcal · 탄${r.carbs}g 단${r.protein}g 지${r.fat}g',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),

                    // 삭제
                    GestureDetector(
                      onTap: () => onDelete(r.id!),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close, size: 16, color: AppColors.textHint),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _nutrientChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label ${value}g',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
