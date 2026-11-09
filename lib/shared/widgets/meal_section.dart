import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../app/theme/tokens.dart';
import '../../core/meal_type.dart';
import '../../data/models/food_record.dart';
import '../meal_style.dart';
import 'calorie_ring.dart';

/// 끼니 하나: 제목 + 합계 + 음식 목록 (+ 기록 추가 버튼)
class MealSection extends StatelessWidget {
  const MealSection({
    super.key,
    required this.mealType,
    required this.records,
    required this.onDelete,
    this.onAdd,
  });

  final String mealType;
  final List<FoodRecord> records;
  final ValueChanged<FoodRecord> onDelete;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final total = records.fold(0, (s, r) => s + r.calories);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.md,
              AppSpace.md,
              AppSpace.md,
              AppSpace.xs,
            ),
            child: Row(
              children: [
                MealBadge(type: mealType, size: 30),
                const SizedBox(width: AppSpace.sm),
                Text(MealType.label(mealType), style: AppText.headline),
                const Spacer(),
                if (total > 0)
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: formatKcal(total),
                          style: AppText.numeric(AppText.headline),
                        ),
                        TextSpan(
                          text: ' kcal',
                          style: AppText.caption.copyWith(color: p.text2),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          for (final r in records)
            FoodTile(record: r, onDelete: () => onDelete(r)),
          if (onAdd != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.md,
                AppSpace.xxs,
                AppSpace.md,
                AppSpace.md,
              ),
              child: _AddButton(
                label: records.isEmpty
                    ? '${MealType.label(mealType)} 기록하기'
                    : '더 추가하기',
                onTap: onAdd!,
              ),
            )
          else if (records.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.md,
                0,
                AppSpace.md,
                AppSpace.md,
              ),
              child: Text(
                '기록이 없어요',
                style: AppText.caption.copyWith(color: p.text3),
              ),
            )
          else
            const SizedBox(height: AppSpace.xs),
        ],
      ),
    );
  }
}

/// 음식 한 줄. 왼쪽으로 밀면 삭제.
class FoodTile extends StatefulWidget {
  const FoodTile({super.key, required this.record, required this.onDelete});
  final FoodRecord record;
  final VoidCallback onDelete;

  @override
  State<FoodTile> createState() => _FoodTileState();
}

class _FoodTileState extends State<FoodTile> {
  // 밀어서 지운 뒤 목록이 새로 고쳐지기 전까지 빈 자리로 둔다
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    final p = context.palette;
    final r = widget.record;
    final onDelete = widget.onDelete;
    return Dismissible(
      key: ValueKey('food-${r.id}-${r.createdAt.microsecondsSinceEpoch}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        setState(() => _dismissed = true);
        onDelete();
      },
      background: Container(
        color: p.over,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpace.lg),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white),
            SizedBox(width: AppSpace.xxs),
            Text(
              '삭제',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: Semantics(
        customSemanticsActions: {CustomSemanticsAction(label: '삭제'): onDelete},
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.xs,
          ),
          child: Row(
            children: [
              FoodThumbnail(path: r.imagePath, size: 48),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.foodName,
                      style: AppText.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text.rich(
                      TextSpan(
                        style: _macro(p),
                        children: [
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: _Dot(p.carbs),
                          ),
                          TextSpan(text: ' ${r.carbs}g  '),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: _Dot(p.protein),
                          ),
                          TextSpan(text: ' ${r.protein}g  '),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: _Dot(p.fat),
                          ),
                          TextSpan(text: ' ${r.fat}g'),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                formatKcal(r.calories),
                style: AppText.numeric(AppText.label),
              ),
              Text(' kcal', style: AppText.micro.copyWith(color: p.text3)),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _macro(AppPalette p) => AppText.numeric(
    AppText.micro,
  ).copyWith(fontWeight: FontWeight.w500, color: p.text2);
}

class _Dot extends StatelessWidget {
  const _Dot(this.color);
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 6,
    height: 6,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.surfaceAlt,
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.control),
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, size: 18, color: p.brand),
              const SizedBox(width: AppSpace.xxs),
              Text(label, style: AppText.label.copyWith(color: p.brand)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 음식 사진 썸네일. 사진이 없거나 지워졌으면 기본 아이콘.
class FoodThumbnail extends StatelessWidget {
  const FoodThumbnail({super.key, required this.path, this.size = 48});
  final String? path;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Icon(Icons.rice_bowl_rounded, size: size * 0.46, color: p.text3),
    );
    if (path == null) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.control),
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
