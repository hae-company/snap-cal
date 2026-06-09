import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/analysis_result.dart';
import '../models/food_record.dart';
import '../services/database_service.dart';
import '../services/prefs_service.dart';
import '../utils/constants.dart';
import '../widgets/nutrient_bar.dart';

class ResultScreen extends StatefulWidget {
  final AnalysisResult result;
  final String imagePath;

  const ResultScreen({super.key, required this.result, required this.imagePath});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  String _selectedMeal = MealType.snack;
  late int _calories;
  late int _carbs;
  late int _protein;
  late int _fat;
  bool _editing = false;

  late final TextEditingController _calCtrl;
  late final TextEditingController _carbsCtrl;
  late final TextEditingController _proteinCtrl;
  late final TextEditingController _fatCtrl;

  @override
  void initState() {
    super.initState();
    _calories = widget.result.calories;
    _carbs = widget.result.carbs;
    _protein = widget.result.protein;
    _fat = widget.result.fat;
    _calCtrl = TextEditingController(text: '$_calories');
    _carbsCtrl = TextEditingController(text: '$_carbs');
    _proteinCtrl = TextEditingController(text: '$_protein');
    _fatCtrl = TextEditingController(text: '$_fat');
    _detectMeal();
  }

  @override
  void dispose() {
    _calCtrl.dispose();
    _carbsCtrl.dispose();
    _proteinCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  Future<void> _detectMeal() async {
    final detected = await PrefsService.autoDetectMealType();
    setState(() => _selectedMeal = detected);
  }

  void _applyEdit() {
    setState(() {
      _calories = int.tryParse(_calCtrl.text) ?? _calories;
      _carbs = int.tryParse(_carbsCtrl.text) ?? _carbs;
      _protein = int.tryParse(_proteinCtrl.text) ?? _protein;
      _fat = int.tryParse(_fatCtrl.text) ?? _fat;
      _editing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;

    return Scaffold(
      appBar: AppBar(title: const Text('AI 분석 결과')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(File(widget.imagePath), height: 220, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 20),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(result.foodName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  // 1인분 칼로리 (메인) — 수정 가능
                  _editing
                    ? SizedBox(
                        width: 120,
                        child: TextField(
                          controller: _calCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary),
                          decoration: const InputDecoration(suffixText: 'kcal', border: UnderlineInputBorder()),
                        ),
                      )
                    : Text('1인분 약 $_calories kcal', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  // 1인분 기준 설명
                  if (result.servingInfo.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                      child: Text(result.servingInfo, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                    ),
                  ],
                  // 전체 칼로리 (참고)
                  if (result.totalCalories > 0 && result.totalCalories != result.calories) ...[
                    const SizedBox(height: 6),
                    Text('사진 전체: 약 ${result.totalCalories} kcal', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                  const SizedBox(height: 6),
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

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('영양성분', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          if (_editing) {
                            _applyEdit();
                          } else {
                            setState(() => _editing = true);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _editing ? AppColors.primary : AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _editing ? '완료' : '수정',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _editing ? Colors.white : AppColors.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _editing
                    ? Column(children: [
                        _editRow('탄수화물', _carbsCtrl, AppColors.carbs),
                        const SizedBox(height: 8),
                        _editRow('단백질', _proteinCtrl, AppColors.protein),
                        const SizedBox(height: 8),
                        _editRow('지방', _fatCtrl, AppColors.fat),
                      ])
                    : Column(children: [
                        NutrientBar(label: '탄수화물', value: _carbs, max: 150, color: AppColors.carbs, unit: 'g'),
                        const SizedBox(height: 12),
                        NutrientBar(label: '단백질', value: _protein, max: 80, color: AppColors.protein, unit: 'g'),
                        const SizedBox(height: 12),
                        NutrientBar(label: '지방', value: _fat, max: 70, color: AppColors.fat, unit: 'g'),
                      ]),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 자동 감지된 식사 + 수동 변경
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${MealType.emoji(_selectedMeal)} ${MealType.label(_selectedMeal)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('자동', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [MealType.breakfast, MealType.lunch, MealType.dinner, MealType.snack]
                        .map((type) => _mealChip(type))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _save(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('기록하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _mealChip(String type) {
    final selected = _selectedMeal == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedMeal = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(MealType.emoji(type), style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 2),
            Text(
              MealType.label(type),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editRow(String label, TextEditingController ctrl, Color color) {
    return Row(
      children: [
        SizedBox(width: 60, child: Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600))),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              suffixText: 'g',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _confidenceBadge() {
    final result = widget.result;
    final color = result.confidence == 'high' ? AppColors.primary
        : result.confidence == 'medium' ? Colors.orange
        : AppColors.danger;
    final label = result.confidence == 'high' ? '높음'
        : result.confidence == 'medium' ? '보통' : '낮음';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Text('신뢰도: $label', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Future<void> _save(BuildContext context) async {
    final result = widget.result;
    final record = FoodRecord(
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      mealType: _selectedMeal,
      foodName: result.foodName,
      calories: _calories,
      carbs: _carbs,
      protein: _protein,
      fat: _fat,
      imagePath: widget.imagePath,
      description: result.description,
    );
    await DatabaseService.insert(record);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${MealType.emoji(_selectedMeal)} ${MealType.label(_selectedMeal)}에 기록했어요!')),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
