import 'package:flutter/material.dart';
import '../services/prefs_service.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _goalCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final goal = await PrefsService.getDailyGoal();
    final key = await PrefsService.getApiKey();
    _goalCtrl.text = '$goal';
    _keyCtrl.text = key;
  }

  Future<void> _save() async {
    await PrefsService.setDailyGoal(int.tryParse(_goalCtrl.text) ?? 2000);
    await PrefsService.setApiKey(_keyCtrl.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('설정이 저장되었어요')));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('설정', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('일일 칼로리 목표', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _goalCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      suffixText: 'kcal',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
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
                  const Text('Gemini API Key', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text('Google AI Studio에서 발급', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _keyCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'API 키 입력',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 식사 시간대 설정
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('식사 시간대 (자동 분류)', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text('해당 시간에 기록하면 자동으로 분류돼요', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  _timeRow('🌅 아침', 6, 10),
                  const SizedBox(height: 8),
                  _timeRow('☀️ 점심', 11, 14),
                  const SizedBox(height: 8),
                  _timeRow('🌙 저녁', 17, 21),
                  const SizedBox(height: 4),
                  const Text('그 외 시간 → 간식', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('저장', style: TextStyle(fontSize: 16)),
          ),

          const SizedBox(height: 32),

          // Branding
          Center(
            child: Text('by hae02y', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _timeRow(String label, int defaultStart, int defaultEnd) {
    return Row(
      children: [
        SizedBox(width: 60, child: Text(label, style: const TextStyle(fontSize: 13))),
        const Spacer(),
        Text('$defaultStart:00', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const Text(' ~ ', style: TextStyle(color: AppColors.textHint)),
        Text('$defaultEnd:00', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }

  @override
  void dispose() {
    _goalCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }
}
