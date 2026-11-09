import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import '../../core/meal_type.dart';
import '../../data/models/food_record.dart';

/// 끼니 하나의 기록 카드 (합계 + 음식 목록)
class MealCard extends StatelessWidget {
  const MealCard({
    super.key,
    required this.mealType,
    required this.records,
    required this.onDelete,
  });

  final String mealType;
  final List<FoodRecord> records;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final total = records.fold(0, (s, r) => s + r.calories);
    final carbs = records.fold(0, (s, r) => s + r.carbs);
    final protein = records.fold(0, (s, r) => s + r.protein);
    final fat = records.fold(0, (s, r) => s + r.fat);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  MealType.emoji(mealType),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: AppSpace.xs),
                Text(
                  MealType.label(mealType),
                  style: AppText.headline.copyWith(fontSize: 16),
                ),
                const Spacer(),
                if (total > 0)
                  Text(
                    '$total kcal',
                    style: AppText.numeric(
                      AppText.label,
                    ).copyWith(color: p.brand),
                  ),
              ],
            ),
            if (records.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  '아직 기록이 없어요',
                  style: AppText.caption.copyWith(color: p.text3),
                ),
              )
            else ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const SizedBox(width: 28),
                  _MacroChip(label: '탄', grams: carbs, color: p.carbs),
                  const SizedBox(width: 6),
                  _MacroChip(label: '단', grams: protein, color: p.protein),
                  const SizedBox(width: 6),
                  _MacroChip(label: '지', grams: fat, color: p.fat),
                ],
              ),
            ],
            for (final r in records)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MealThumbnail(path: r.imagePath, size: 44),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.foodName,
                            style: AppText.label.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${r.calories}kcal · 탄${r.carbs}g 단${r.protein}g 지${r.fat}g',
                            style: AppText.micro.copyWith(
                              fontWeight: FontWeight.w500,
                              color: p.text2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: r.id == null ? null : () => onDelete(r.id!),
                      icon: Icon(Icons.close, size: 16, color: p.text3),
                      tooltip: '삭제',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({
    required this.label,
    required this.grams,
    required this.color,
  });
  final String label;
  final int grams;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        '$label ${grams}g',
        style: AppText.micro.copyWith(color: color),
      ),
    );
  }
}

/// 음식 사진 썸네일. 사진이 없거나 지워졌으면 기본 아이콘.
class MealThumbnail extends StatelessWidget {
  const MealThumbnail({super.key, required this.path, this.size = 44});
  final String? path;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: p.brandSubtle,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Icon(Icons.restaurant, size: size * 0.45, color: p.brand),
    );
    if (path == null) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: Image.file(
        File(path!),
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * 3).round(),
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }
}
