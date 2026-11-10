import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 기록에 붙는 음식 사진 보관.
///
/// 촬영 도구가 주는 경로는 임시 폴더라 언젠가 지워지고, iOS는 앱을 업데이트하면
/// 앱 폴더 경로 자체가 바뀐다. 그래서 사진을 앱 문서 폴더에 복사하고
/// 기록에는 `meal_photos/xxx.jpg` 같은 **상대 경로**만 저장한다.
abstract final class PhotoStore {
  static const _folder = 'meal_photos';
  static Directory? _docs;

  /// 앱 시작 시 한 번. 실패해도 앱은 동작한다 (사진만 안 보임).
  static Future<void> init() async {
    try {
      _docs = await getApplicationDocumentsDirectory();
    } catch (_) {
      _docs = null;
    }
  }

  /// 시험용
  static void debugSetDirectory(Directory? dir) => _docs = dir;

  /// 사진을 보관 폴더로 복사하고 저장용 상대 경로를 돌려준다.
  /// 보관 폴더를 못 쓰면 원래 경로를 그대로 돌려준다.
  static Future<String> keep(String sourcePath) async {
    final docs = _docs;
    if (docs == null) return sourcePath;
    final dir = Directory('${docs.path}/$_folder');
    await dir.create(recursive: true);
    final name = '${DateTime.now().microsecondsSinceEpoch}.jpg';
    await File(sourcePath).copy('${dir.path}/$name');
    return '$_folder/$name';
  }

  /// 기록에 저장된 경로를 실제 파일 경로로. 예전 기록의 절대 경로도 그대로 쓴다.
  static String? resolve(String? stored) {
    if (stored == null || stored.isEmpty) return null;
    if (stored.startsWith('/')) return stored;
    final docs = _docs;
    return docs == null ? null : '${docs.path}/$stored';
  }

  /// 보관 폴더의 사진만 지운다 (예전 기록의 임시 경로는 건드리지 않음)
  static Future<void> delete(String? stored) async {
    if (stored == null || !stored.startsWith('$_folder/')) return;
    final path = resolve(stored);
    if (path == null) return;
    try {
      await File(path).delete();
    } catch (_) {}
  }
}
