import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/prefs_service.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _goalCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();
  bool _keyVisible = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final goal = await PrefsService.getDailyGoal();
    final key = await PrefsService.getApiKey();
    final nutrients = await PrefsService.getNutrientGoals();
    _goalCtrl.text = '$goal';
    _carbsCtrl.text = '${nutrients['carbs']}';
    _proteinCtrl.text = '${nutrients['protein']}';
    _fatCtrl.text = '${nutrients['fat']}';
    _keyCtrl.text = key;
    setState(() {});
  }

  Future<void> _save() async {
    await PrefsService.setDailyGoal(int.tryParse(_goalCtrl.text) ?? 2000);
    await PrefsService.setNutrientGoals(
      int.tryParse(_carbsCtrl.text) ?? 250,
      int.tryParse(_proteinCtrl.text) ?? 60,
      int.tryParse(_fatCtrl.text) ?? 55,
    );
    await PrefsService.setApiKey(_keyCtrl.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('설정이 저장되었어요'), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Text('설정', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),

          // ===== 목표 섹션 =====
          _sectionHeader('🎯 목표 설정'),

          _settingCard([
            _inputTile('일일 칼로리 목표', _goalCtrl, 'kcal', Icons.local_fire_department),
          ]),

          const SizedBox(height: 8),

          _settingCard([
            _nutrientTile('탄수화물', _carbsCtrl, AppColors.carbs),
            const Divider(height: 1),
            _nutrientTile('단백질', _proteinCtrl, AppColors.protein),
            const Divider(height: 1),
            _nutrientTile('지방', _fatCtrl, AppColors.fat),
          ]),

          const SizedBox(height: 20),

          // ===== 식사 시간대 =====
          _sectionHeader('⏰ 식사 시간대'),

          _settingCard([
            _timeTile('🌅 아침', '06:00 ~ 10:00'),
            const Divider(height: 1),
            _timeTile('☀️ 점심', '11:00 ~ 14:00'),
            const Divider(height: 1),
            _timeTile('🌙 저녁', '17:00 ~ 21:00'),
            const Divider(height: 1),
            _timeTile('🍪 간식', '그 외 시간'),
          ]),

          const SizedBox(height: 20),

          // ===== AI 설정 =====
          _sectionHeader('🤖 AI 설정'),

          _settingCard([
            ListTile(
              title: const Text('Gemini API Key'),
              subtitle: Text(
                _keyCtrl.text.isEmpty ? '설정되지 않음' : '••••••${_keyCtrl.text.substring(_keyCtrl.text.length > 6 ? _keyCtrl.text.length - 4 : 0)}',
                style: TextStyle(fontSize: 13, color: _keyCtrl.text.isEmpty ? AppColors.danger : AppColors.textSecondary),
              ),
              leading: const Icon(Icons.key, color: AppColors.primary),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
              onTap: () => _showApiKeyDialog(),
            ),
            const Divider(height: 1),
            ListTile(
              title: const Text('AI 모델'),
              subtitle: const Text('Gemini 2.5 Flash Lite', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              leading: const Icon(Icons.smart_toy, color: AppColors.primary),
            ),
          ]),

          const SizedBox(height: 20),

          // ===== 저장 버튼 =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('저장', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),

          const SizedBox(height: 28),

          // ===== 데이터 관리 =====
          _sectionHeader('📦 데이터 관리'),

          _settingCard([
            ListTile(
              title: const Text('기록 전체 삭제'),
              subtitle: const Text('모든 식단 기록이 삭제돼요', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              leading: const Icon(Icons.delete_outline, color: AppColors.danger),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
              onTap: () => _showResetDialog(),
            ),
          ]),

          const SizedBox(height: 20),

          // ===== 정보 =====
          _sectionHeader('ℹ️ 정보'),

          _settingCard([
            const ListTile(
              title: Text('버전'),
              trailing: Text('1.0.0', style: TextStyle(color: AppColors.textSecondary)),
              leading: Icon(Icons.info_outline, color: AppColors.textSecondary),
            ),
            const Divider(height: 1),
            ListTile(
              title: const Text('개인정보처리방침'),
              leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.textSecondary),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
              onTap: () => _showPolicy('개인정보처리방침', _privacyPolicy),
            ),
            const Divider(height: 1),
            ListTile(
              title: const Text('이용약관'),
              leading: const Icon(Icons.description_outlined, color: AppColors.textSecondary),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
              onTap: () => _showPolicy('이용약관', _termsOfService),
            ),
            const Divider(height: 1),
            ListTile(
              title: const Text('오픈소스 라이선스'),
              leading: const Icon(Icons.code, color: AppColors.textSecondary),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
              onTap: () => showLicensePage(context: context, applicationName: 'SnapCal', applicationVersion: '1.0.0'),
            ),
            const Divider(height: 1),
            ListTile(
              title: const Text('문의하기'),
              subtitle: const Text('hae02y@gmail.com', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              leading: const Icon(Icons.mail_outline, color: AppColors.textSecondary),
            ),
          ]),

          const SizedBox(height: 24),

          // Branding
          const Center(
            child: Column(
              children: [
                Text('SnapCal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textHint)),
                SizedBox(height: 2),
                Text('by hae02y', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== 위젯 헬퍼 =====

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
    );
  }

  Widget _settingCard(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Column(children: children),
      ),
    );
  }

  Widget _inputTile(String label, TextEditingController ctrl, String suffix, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      trailing: SizedBox(
        width: 100,
        child: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            suffixText: suffix,
            isDense: true,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ),
    );
  }

  Widget _nutrientTile(String label, TextEditingController ctrl, Color color) {
    return ListTile(
      leading: CircleAvatar(radius: 6, backgroundColor: color),
      title: Text(label),
      trailing: SizedBox(
        width: 80,
        child: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          decoration: const InputDecoration(
            suffixText: 'g',
            isDense: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ),
    );
  }

  Widget _timeTile(String label, String time) {
    return ListTile(
      dense: true,
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: Text(time, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
    );
  }

  // ===== 다이얼로그 =====

  void _showApiKeyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gemini API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Google AI Studio에서 무료로 발급받을 수 있어요', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: _keyCtrl,
              obscureText: !_keyVisible,
              decoration: InputDecoration(
                hintText: 'API 키 입력',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: Icon(_keyVisible ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _keyVisible = !_keyVisible),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          FilledButton(onPressed: () { setState(() {}); Navigator.pop(ctx); }, child: const Text('확인')),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('기록 전체 삭제'),
        content: const Text('모든 식단 기록이 삭제되며 복구할 수 없어요.\n정말 삭제하시겠어요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              final db = await DatabaseService.database;
              await db.delete('food_records');
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('모든 기록이 삭제되었어요'), behavior: SnackBarBehavior.floating),
              );
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _showPolicy(String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  controller: ctrl,
                  padding: const EdgeInsets.all(20),
                  child: Text(content, style: const TextStyle(fontSize: 14, height: 1.7, color: AppColors.textSecondary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _goalCtrl.dispose();
    _carbsCtrl.dispose();
    _proteinCtrl.dispose();
    _fatCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }
}

// ===== 약관 텍스트 =====

const _privacyPolicy = '''
SnapCal 개인정보처리방침

1. 수집하는 개인정보
본 앱은 사용자의 개인정보를 서버에 수집하지 않습니다.
- 음식 사진: AI 분석을 위해 Gemini API로 전송되며, 분석 후 서버에 저장되지 않습니다.
- 식단 기록: 사용자 기기의 로컬 데이터베이스에만 저장됩니다.
- API 키: 사용자 기기에만 저장되며 외부로 전송되지 않습니다.

2. 제3자 제공
- 음식 사진은 Google Gemini API로 전송되어 분석됩니다.
- Google의 개인정보처리방침이 적용됩니다.

3. 데이터 보관
- 모든 데이터는 사용자 기기에만 저장됩니다.
- 앱 삭제 시 모든 데이터가 함께 삭제됩니다.
- 설정에서 수동으로 데이터를 삭제할 수 있습니다.

4. 문의
개인정보 관련 문의: hae02y@gmail.com

시행일: 2026년 6월 9일
''';

const _termsOfService = '''
SnapCal 이용약관

1. 서비스 소개
SnapCal은 음식 사진을 AI로 분석하여 칼로리와 영양소를 추정하는 식단 관리 앱입니다.

2. AI 분석 정확도
- 본 앱의 칼로리/영양소 추정은 AI 기반 예측이며, 정확한 수치가 아닙니다.
- 의료적 목적이나 정밀한 식단 관리를 위해서는 전문가 상담을 권장합니다.
- AI 분석 결과에 대해 개발자는 책임을 지지 않습니다.

3. 사용자 책임
- 사용자는 본인의 Gemini API 키를 사용하며, 해당 키의 관리 책임은 사용자에게 있습니다.
- API 사용량에 따른 비용은 사용자가 부담합니다.

4. 지적재산권
- 본 앱의 소스코드 및 디자인에 대한 권리는 개발자에게 있습니다.

5. 면책사항
- 본 앱 사용으로 발생하는 건강 관련 문제에 대해 개발자는 책임을 지지 않습니다.
- 서비스는 현재 상태 그대로 제공되며, 특정 목적에의 적합성을 보증하지 않습니다.

6. 약관 변경
- 본 약관은 사전 고지 후 변경될 수 있습니다.

시행일: 2026년 6월 9일
''';
