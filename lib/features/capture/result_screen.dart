import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/tokens.dart';
import '../../core/date_key.dart';
import '../../core/meal_type.dart';
import '../../data/models/analysis_result.dart';
import '../../data/models/food_record.dart';
import '../../data/providers.dart';
import '../../shared/widgets/nutrient_bar.dart';

class ResultArgs {
  const ResultArgs({required this.result, required this.imagePath});
  final AnalysisResult result;
  final String imagePath;
}

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key, required this.args});
  final ResultArgs args;

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  late String _meal = MealType.detect(
    DateTime.now(),
    ref.read(mealTimesProvider),
  );
  late int _calories = widget.args.result.calories;
  late int _carbs = widget.args.result.carbs;
  late int _protein = widget.args.result.protein;
  late int _fat = widget.args.result.fat;
  bool _saving = false;

  AnalysisResult get _result => widget.args.result;

  Future<void> _edit(
    String label,
    int current,
    ValueChanged<int> onSave,
  ) async {
    final ctrl = TextEditingController(text: '$current');
    final value = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$label 수정'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofocus: true,
          decoration: InputDecoration(
            suffixText: label == '칼로리' ? 'kcal' : 'g',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(ctrl.text) ?? 0),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (value != null) setState(() => onSave(value));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref
        .read(mealActionsProvider)
        .add(
          FoodRecord(
            date: dateKey(DateTime.now()),
            mealType: _meal,
            foodName: _result.foodName,
            calories: _calories,
            carbs: _carbs,
            protein: _protein,
            fat: _fat,
            imagePath: widget.args.imagePath,
            description: _result.description,
          ),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${MealType.emoji(_meal)} ${MealType.label(_meal)}에 기록했어요!',
        ),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('AI 분석 결과')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.md),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Image.file(
              File(widget.args.imagePath),
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  Container(height: 220, color: p.surfaceAlt),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: Column(
                children: [
                  Text(
                    _result.foodName,
                    style: AppText.title1,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpace.xs),
                  InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                    onTap: () => _edit('칼로리', _calories, (v) => _calories = v),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '1인분 약 $_calories kcal',
                          style: AppText.numeric(AppText.title1).copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: p.brand,
                          ),
                        ),
                        const SizedBox(width: AppSpace.xxs),
                        Icon(Icons.edit, size: 14, color: p.text3),
                      ],
                    ),
                  ),
                  if (_result.servingInfo.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.xxs),
                    _Pill(
                      text: _result.servingInfo,
                      color: p.brand,
                      background: p.brandSubtle,
                    ),
                  ],
                  if (_result.totalCalories > 0 &&
                      _result.totalCalories != _result.calories) ...[
                    const SizedBox(height: 6),
                    Text(
                      '사진 전체: 약 ${_result.totalCalories} kcal',
                      style: AppText.caption.copyWith(color: p.text2),
                    ),
                  ],
                  const SizedBox(height: 6),
                  _confidence(p),
                  if (_result.description.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      _result.description,
                      style: AppText.caption.copyWith(color: p.text2),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '영양성분',
                        style: AppText.headline.copyWith(fontSize: 16),
                      ),
                      const Spacer(),
                      Text(
                        '탭하여 수정',
                        style: AppText.micro.copyWith(
                          fontWeight: FontWeight.w500,
                          color: p.text3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.md),
                  _tapToEdit('탄수화물', _carbs, 150, p.carbs, (v) => _carbs = v),
                  const SizedBox(height: AppSpace.sm),
                  _tapToEdit(
                    '단백질',
                    _protein,
                    80,
                    p.protein,
                    (v) => _protein = v,
                  ),
                  const SizedBox(height: AppSpace.sm),
                  _tapToEdit('지방', _fat, 70, p.fat, (v) => _fat = v),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${MealType.emoji(_meal)} ${MealType.label(_meal)}',
                        style: AppText.headline.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: AppSpace.xxs),
                      _Pill(
                        text: '자동',
                        color: p.brand,
                        background: p.brandSubtle,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [for (final t in MealType.all) _mealChip(t, p)],
                  ),
                  const SizedBox(height: AppSpace.md),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('기록하기'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpace.xxl),
        ],
      ),
    );
  }

  Widget _tapToEdit(
    String label,
    int value,
    int max,
    Color color,
    ValueChanged<int> onSave,
  ) {
    return InkWell(
      onTap: () => _edit(label, value, onSave),
      child: NutrientBar(label: label, value: value, max: max, color: color),
    );
  }

  Widget _mealChip(String type, AppPalette p) {
    final selected = _meal == type;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.control),
        onTap: () => setState(() => _meal = type),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? p.brand : p.brandSubtle,
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          child: Column(
            children: [
              Text(MealType.emoji(type), style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 2),
              Text(
                MealType.label(type),
                style: AppText.micro.copyWith(
                  color: selected ? p.onBrand : p.text1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _confidence(AppPalette p) {
    final (label, color) = switch (_result.confidence) {
      'high' => ('높음', p.brand),
      'medium' => ('보통', p.warning),
      _ => ('낮음', p.over),
    };
    return _Pill(
      text: '신뢰도: $label',
      color: color,
      background: color.withAlpha(26),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    required this.color,
    required this.background,
  });
  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        text,
        style: AppText.micro.copyWith(fontSize: 12, color: color),
      ),
    );
  }
}
