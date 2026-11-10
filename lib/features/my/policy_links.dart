import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/config.dart';
import '../../app/theme/tokens.dart';
import '../../shared/widgets/sheet_handle.dart';
import 'policy_texts.dart';

/// 이용약관. 웹 주소가 설정돼 있으면 브라우저로, 없으면 앱 안 원문을 연다.
Future<void> openTerms(BuildContext context) =>
    _open(context, AppConfig.termsUrl, '이용약관', termsOfServiceText);

/// 개인정보처리방침
Future<void> openPrivacy(BuildContext context) =>
    _open(context, AppConfig.privacyUrl, '개인정보처리방침', privacyPolicyText);

Future<void> _open(
  BuildContext context,
  String url,
  String title,
  String text,
) async {
  if (url.isNotEmpty &&
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
    return;
  }
  if (context.mounted) showPolicySheet(context, title, text);
}

void showPolicySheet(BuildContext context, String title, String content) {
  final p = context.palette;
  showModalBottomSheet(
    context: context,
    useRootNavigator: true, // 하단 탭 위로 띄운다
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      builder: (_, scroll) => Container(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: AppSpace.xs),
            const SheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.screen,
                0,
                AppSpace.xs,
                AppSpace.xs,
              ),
              child: Row(
                children: [
                  Text(title, style: AppText.title2.copyWith(fontSize: 18)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: '닫기',
                    onPressed: () => Navigator.pop(sheetCtx),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                controller: scroll,
                padding: const EdgeInsets.all(AppSpace.screen),
                child: Text(
                  content,
                  style: AppText.label.copyWith(
                    fontWeight: FontWeight.w400,
                    height: 1.7,
                    color: p.text2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
