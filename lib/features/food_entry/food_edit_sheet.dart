import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/tokens.dart';
import '../../data/models/food_record.dart';
import '../../data/providers.dart';
import '../../shared/widgets/number_field.dart';
import '../../shared/widgets/pickers.dart';
import '../../shared/widgets/sheet_handle.dart';

/// 기록 하나 수정: 이름, 양, 칼로리·영양소, 끼니. 삭제도 여기서.
Future<void> showFoodEditSheet(BuildContext context, FoodRecord record) {
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (_) => FoodEditSheet(record: record),
  );
}

class FoodEditSheet extends ConsumerStatefulWidget {
  const FoodEditSheet({super.key, required this.record});
  final FoodRecord record;

  @override
  ConsumerState<FoodEditSheet> createState() => _FoodEditSheetState();
}

class _FoodEditSheetState extends ConsumerState<FoodEditSheet> {
  late FoodRecord _r = widget.record;
  late final _name = TextEditingController(text: _r.foodName);
  late final _kcal = TextEditingController(text: '${_r.calories}');
  late final _carbs = TextEditingController(text: '${_r.carbs}');
  late final _protein = TextEditingController(text: '${_r.protein}');
  late final _fat = TextEditingController(text: '${_r.fat}');

  @override
  void dispose() {
    for (final c in [_name, _kcal, _carbs, _protein, _fat]) {
      c.dispose();
    }
    super.dispose();
  }

  /// 입력칸 값을 기록에 반영
  FoodRecord _current() {
    int n(TextEditingController c, int fallback) =>
        int.tryParse(c.text) ?? fallback;
    return _r.copyWith(
      foodName: _name.text.trim().isEmpty ? _r.foodName : _name.text.trim(),
      calories: n(_kcal, _r.calories),
      carbs: n(_carbs, _r.carbs),
      protein: n(_protein, _r.protein),
      fat: n(_fat, _r.fat),
    );
  }

  void _changeServings(double v) {
    setState(() {
      _r = _current().withServings(v);
      _kcal.text = '${_r.calories}';
      _carbs.text = '${_r.carbs}';
      _protein.text = '${_r.protein}';
      _fat.text = '${_r.fat}';
    });
  }

  Future<void> _save() async {
    await ref.read(mealActionsProvider).update(_current());
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    await ref.read(mealActionsProvider).delete(_r.id!);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${_r.foodName}을(를) 지웠어요')));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.xs,
        AppSpace.screen,
        MediaQuery.viewInsetsOf(context).bottom + AppSpace.md,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              Row(
                children: [
                  const Expanded(child: Text('기록 수정', style: AppText.title2)),
                  TextButton.icon(
                    onPressed: _delete,
                    style: TextButton.styleFrom(foregroundColor: p.over),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('삭제'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              TextField(
                controller: _name,
                decoration: const InputDecoration(hintText: '음식 이름'),
              ),
              const SizedBox(height: AppSpace.lg),
              Text('양', style: AppText.label.copyWith(color: p.text2)),
              const SizedBox(height: AppSpace.xs),
              ServingStepper(value: _r.servings, onChanged: _changeServings),
              const SizedBox(height: AppSpace.lg),
              NumberField(
                label: '칼로리',
                controller: _kcal,
                unit: 'kcal',
                color: p.brand,
              ),
              const SizedBox(height: AppSpace.sm),
              Row(
                children: [
                  Expanded(
                    child: NumberField(
                      label: '탄수화물',
                      controller: _carbs,
                      unit: 'g',
                      color: p.carbs,
                    ),
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Expanded(
                    child: NumberField(
                      label: '단백질',
                      controller: _protein,
                      unit: 'g',
                      color: p.protein,
                    ),
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Expanded(
                    child: NumberField(
                      label: '지방',
                      controller: _fat,
                      unit: 'g',
                      color: p.fat,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              Text('끼니', style: AppText.label.copyWith(color: p.text2)),
              const SizedBox(height: AppSpace.xs),
              MealPicker(
                value: _r.mealType,
                onChanged: (t) =>
                    setState(() => _r = _current().copyWith(mealType: t)),
              ),
              const SizedBox(height: AppSpace.xl),
              FilledButton(onPressed: _save, child: const Text('저장')),
            ],
          ),
        ),
      ),
    );
  }
}
