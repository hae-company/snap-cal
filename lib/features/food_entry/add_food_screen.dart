import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme/tokens.dart';
import '../../core/date_key.dart';
import '../../core/meal_type.dart';
import '../../data/models/food_item.dart';
import '../../data/models/food_record.dart';
import '../../data/providers.dart';
import '../../data/repositories/food_catalog_repository.dart';
import '../../data/services/photo_store.dart';
import '../../shared/widgets/calorie_ring.dart';
import '../../shared/widgets/number_field.dart';
import '../../shared/widgets/pickers.dart';
import '../../shared/widgets/sheet_handle.dart';

final _catalogProvider = FutureProvider<List<FoodItem>>(
  (ref) => ref.watch(foodCatalogRepositoryProvider).all(),
);

/// 검색해서 기록하기. 사진 없이 기록하거나, 최근에 먹은 음식을 한 번에 다시 넣는다.
class AddFoodScreen extends ConsumerStatefulWidget {
  const AddFoodScreen({super.key, this.presetMeal, this.date, this.photoPath});
  final String? presetMeal;

  /// AI 없이 찍은 사진. 있으면 이 화면에서 기록하는 음식에 붙인다.
  final String? photoPath;

  /// 기록할 날짜 (yyyy-MM-dd). 없으면 오늘.
  final String? date;

  @override
  ConsumerState<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends ConsumerState<AddFoodScreen> {
  final _query = TextEditingController();
  late String _meal =
      widget.presetMeal ??
      MealType.detect(DateTime.now(), ref.read(mealTimesProvider));
  String? _category;

  String get _date => widget.date ?? dateKey(DateTime.now());

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  /// 보관 폴더에 복사한 사진 경로 (한 번만 복사)
  String? _keptPhoto;

  Future<void> _save(FoodRecord record) async {
    final photo = widget.photoPath;
    if (photo != null) {
      _keptPhoto ??= await PhotoStore.keep(photo);
      record = record.copyWith(imagePath: _keptPhoto);
    }
    await ref.read(mealActionsProvider).add(record);
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${MealType.label(record.mealType)}에 ${record.foodName}을(를) 기록했어요',
        ),
      ),
    );
    context.pop();
  }

  Future<void> _pickPortion(FoodItem item) async {
    final record = await showModalBottomSheet<FoodRecord>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PortionSheet(item: item, meal: _meal, date: _date),
    );
    if (record != null) await _save(record);
  }

  Future<void> _manual() async {
    final record = await showModalBottomSheet<FoodRecord>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ManualSheet(
        meal: _meal,
        date: _date,
        initialName: _query.text.trim(),
      ),
    );
    if (record != null) await _save(record);
  }

  /// 예전 기록을 그대로 다시 넣는다
  Future<void> _quickAdd(FoodRecord r) => _save(
    FoodRecord(
      date: _date,
      mealType: _meal,
      foodName: r.foodName,
      calories: r.calories,
      carbs: r.carbs,
      protein: r.protein,
      fat: r.fat,
      servings: r.servings,
      source: r.source,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final catalog = ref.watch(_catalogProvider).value ?? const <FoodItem>[];
    final quick = ref.watch(quickFoodsProvider).value;
    final q = _query.text.trim();
    final results = q.isNotEmpty
        ? searchFoods(catalog, q)
        : _category != null
        ? catalog.where((f) => f.category == _category).toList()
        : const <FoodItem>[];
    final categories = <String>{for (final f in catalog) f.category}.toList();
    final isToday = _date == dateKey(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isToday
              ? '음식 추가'
              : '${DateFormat('M월 d일', 'ko').format(DateTime.parse(_date))} 기록 추가',
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          tooltip: '닫기',
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: Column(
        children: [
          if (widget.photoPath != null) _PhotoBanner(path: widget.photoPath!),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.screen,
              0,
              AppSpace.screen,
              AppSpace.sm,
            ),
            child: MealPicker(
              value: _meal,
              onChanged: (t) => setState(() => _meal = t),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
            child: TextField(
              controller: _query,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: '음식 이름 (초성도 돼요: ㄱㅊㅉㄱ)',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: q.isEmpty
                    ? null
                    : IconButton(
                        onPressed: _query.clear,
                        tooltip: '지우기',
                        icon: const Icon(Icons.cancel_rounded),
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.screen,
                vertical: AppSpace.xs,
              ),
              children: [
                for (final c in categories)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpace.xs),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: _category == c && q.isEmpty,
                      showCheckmark: false,
                      selectedColor: p.brandSubtle,
                      side: BorderSide(
                        color: _category == c && q.isEmpty ? p.brand : p.border,
                      ),
                      onSelected: (on) {
                        _query.clear();
                        setState(() => _category = on ? c : null);
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.screen,
                AppSpace.xs,
                AppSpace.screen,
                AppSpace.xxl,
              ),
              children: [
                if (q.isEmpty && _category == null) ...[
                  if (quick != null && quick.frequent.isNotEmpty) ...[
                    const _Header('자주 먹은 음식'),
                    for (final r in quick.frequent.take(5))
                      _QuickRow(record: r, onAdd: () => _quickAdd(r)),
                    const SizedBox(height: AppSpace.md),
                  ],
                  if (quick != null && quick.recent.isNotEmpty) ...[
                    const _Header('최근 먹은 음식'),
                    for (final r in quick.recent)
                      _QuickRow(record: r, onAdd: () => _quickAdd(r)),
                  ] else
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpace.xxl,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.manage_search_rounded,
                            size: 40,
                            color: p.text3,
                          ),
                          const SizedBox(height: AppSpace.xs),
                          Text(
                            '먹은 음식을 검색해보세요',
                            style: AppText.body.copyWith(color: p.text3),
                          ),
                        ],
                      ),
                    ),
                ] else ...[
                  for (final f in results)
                    _FoodRow(item: f, onTap: () => _pickPortion(f)),
                  if (results.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpace.xl,
                      ),
                      child: Center(
                        child: Text(
                          "'$q' 검색 결과가 없어요",
                          style: AppText.body.copyWith(color: p.text3),
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: AppSpace.md),
                OutlinedButton.icon(
                  onPressed: _manual,
                  icon: Icon(Icons.edit_note_rounded, color: p.brand),
                  label: const Text('찾는 음식이 없나요? 직접 입력'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.xs, top: AppSpace.xs),
    child: Text(
      text,
      style: AppText.label.copyWith(color: context.palette.text2),
    ),
  );
}

class _FoodRow extends StatelessWidget {
  const _FoodRow({required this.item, required this.onTap});
  final FoodItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpace.sm,
          horizontal: AppSpace.xxs,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: AppText.label),
                  const SizedBox(height: 2),
                  Text(
                    '${item.serving} (${item.grams}g) · 탄 ${item.carbs} 단 ${item.protein} 지 ${item.fat}',
                    style: AppText.micro.copyWith(
                      fontWeight: FontWeight.w400,
                      color: p.text2,
                    ),
                  ),
                ],
              ),
            ),
            Text(formatKcal(item.kcal), style: AppText.numeric(AppText.label)),
            Text(' kcal', style: AppText.micro.copyWith(color: p.text3)),
            const SizedBox(width: AppSpace.xs),
            Icon(Icons.add_circle_rounded, color: p.brand),
          ],
        ),
      ),
    );
  }
}

class _QuickRow extends StatelessWidget {
  const _QuickRow({required this.record, required this.onAdd});
  final FoodRecord record;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.foodName,
                  style: AppText.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${formatServings(record.servings)}인분 · 탄 ${record.carbs} 단 ${record.protein} 지 ${record.fat}',
                  style: AppText.micro.copyWith(
                    fontWeight: FontWeight.w400,
                    color: p.text2,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatKcal(record.calories),
            style: AppText.numeric(AppText.label),
          ),
          Text(' kcal', style: AppText.micro.copyWith(color: p.text3)),
          IconButton(
            onPressed: onAdd,
            tooltip: '${record.foodName} 바로 추가',
            icon: Icon(Icons.add_circle_rounded, color: p.brand),
          ),
        ],
      ),
    );
  }
}

/// 목록에서 고른 음식의 양 정하기
class _PortionSheet extends StatefulWidget {
  const _PortionSheet({
    required this.item,
    required this.meal,
    required this.date,
  });
  final FoodItem item;
  final String meal;
  final String date;

  @override
  State<_PortionSheet> createState() => _PortionSheetState();
}

class _PortionSheetState extends State<_PortionSheet> {
  double _servings = 1;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final f = widget.item;
    int s(int v) => (v * _servings).round();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.screen,
          AppSpace.xs,
          AppSpace.screen,
          AppSpace.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            Text(f.name, style: AppText.title2),
            Text(
              '1인분 = ${f.serving} (${f.grams}g)',
              style: AppText.caption.copyWith(color: p.text2),
            ),
            const SizedBox(height: AppSpace.lg),
            ServingStepper(
              value: _servings,
              onChanged: (v) => setState(() => _servings = v),
            ),
            const SizedBox(height: AppSpace.lg),
            _NutritionLine(
              kcal: s(f.kcal),
              carbs: s(f.carbs),
              protein: s(f.protein),
              fat: s(f.fat),
            ),
            const SizedBox(height: AppSpace.lg),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                FoodRecord(
                  date: widget.date,
                  mealType: widget.meal,
                  foodName: f.name,
                  calories: s(f.kcal),
                  carbs: s(f.carbs),
                  protein: s(f.protein),
                  fat: s(f.fat),
                  servings: _servings,
                  source: RecordSource.db,
                ),
              ),
              child: Text('${MealType.label(widget.meal)}에 추가'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 이름과 칼로리를 직접 입력
class _ManualSheet extends StatefulWidget {
  const _ManualSheet({
    required this.meal,
    required this.date,
    required this.initialName,
  });
  final String meal;
  final String date;
  final String initialName;

  @override
  State<_ManualSheet> createState() => _ManualSheetState();
}

class _ManualSheetState extends State<_ManualSheet> {
  late final _name = TextEditingController(text: widget.initialName);
  final _kcal = TextEditingController();
  final _carbs = TextEditingController();
  final _protein = TextEditingController();
  final _fat = TextEditingController();

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
    _kcal.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [_name, _kcal, _carbs, _protein, _fat]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valid =>
      _name.text.trim().isNotEmpty && (int.tryParse(_kcal.text) ?? -1) >= 0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    int n(TextEditingController c) => int.tryParse(c.text) ?? 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.xs,
        AppSpace.screen,
        MediaQuery.viewInsetsOf(context).bottom + AppSpace.md,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            const Text('직접 입력', style: AppText.title2),
            const SizedBox(height: AppSpace.md),
            TextField(
              controller: _name,
              autofocus: widget.initialName.isEmpty,
              decoration: const InputDecoration(hintText: '음식 이름'),
            ),
            const SizedBox(height: AppSpace.sm),
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
            FilledButton(
              onPressed: !_valid
                  ? null
                  : () => Navigator.pop(
                      context,
                      FoodRecord(
                        date: widget.date,
                        mealType: widget.meal,
                        foodName: _name.text.trim(),
                        calories: n(_kcal),
                        carbs: n(_carbs),
                        protein: n(_protein),
                        fat: n(_fat),
                        source: RecordSource.manual,
                      ),
                    ),
              child: Text('${MealType.label(widget.meal)}에 추가'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NutritionLine extends StatelessWidget {
  const _NutritionLine({
    required this.kcal,
    required this.carbs,
    required this.protein,
    required this.fat,
  });
  final int kcal;
  final int carbs;
  final int protein;
  final int fat;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget cell(String label, String v, Color c) => Expanded(
      child: Column(
        children: [
          Text(label, style: AppText.micro.copyWith(color: p.text2)),
          const SizedBox(height: 2),
          Text(v, style: AppText.numeric(AppText.headline).copyWith(color: c)),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          cell('칼로리', formatKcal(kcal), p.text1),
          cell('탄수화물', '${carbs}g', p.carbs),
          cell('단백질', '${protein}g', p.protein),
          cell('지방', '${fat}g', p.fat),
        ],
      ),
    );
  }
}

/// AI 없이 찍은 사진: 이 사진과 함께 기록된다는 안내
class _PhotoBanner extends StatelessWidget {
  const _PhotoBanner({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        0,
        AppSpace.screen,
        AppSpace.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpace.sm),
        decoration: BoxDecoration(
          color: p.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.control),
              child: Image.file(
                File(path),
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                cacheWidth: 156,
                errorBuilder: (_, _, _) => Container(
                  width: 52,
                  height: 52,
                  color: p.border,
                  child: Icon(Icons.photo_rounded, color: p.text3),
                ),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('사진과 함께 기록해요', style: AppText.label),
                  Text(
                    '음식을 검색하거나 직접 입력해 주세요',
                    style: AppText.caption.copyWith(color: p.text2),
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
