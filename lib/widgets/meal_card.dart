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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                padding: EdgeInsets.only(top: 8),
                child: Text('아직 기록이 없어요', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
              ),
            for (final r in records)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const SizedBox(width: 28),
                    Expanded(child: Text(r.foodName, style: const TextStyle(fontSize: 14))),
                    Text('${r.calories} kcal', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => onDelete(r.id!),
                      child: const Icon(Icons.close, size: 16, color: AppColors.textHint),
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
