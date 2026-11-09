import 'dart:convert';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/analysis_result.dart';
import 'food_analysis_prompt.dart';

/// 음식 사진 분석.
///
/// 2단계(AI 서버)에서 Cloud Function을 호출하는 구현으로 바꾼다.
/// 그때 API 키는 앱에서 완전히 사라진다.
abstract interface class FoodAnalysisRepository {
  Future<AnalysisResult> analyze(Uint8List jpegBytes);
}

class MissingApiKeyException implements Exception {
  const MissingApiKeyException();
  @override
  String toString() => '설정에서 Gemini API 키를 먼저 입력해주세요';
}

/// 임시 구현: 앱에서 Gemini를 직접 호출한다 (사용자 API 키 필요).
class GeminiDirectAnalysisRepository implements FoodAnalysisRepository {
  GeminiDirectAnalysisRepository(this._readApiKey);
  final String Function() _readApiKey;

  static const model = 'gemini-2.5-flash-lite';

  @override
  Future<AnalysisResult> analyze(Uint8List jpegBytes) async {
    final apiKey = _readApiKey();
    if (apiKey.isEmpty) throw const MissingApiKeyException();

    final gemini = GenerativeModel(model: model, apiKey: apiKey);
    final response = await gemini.generateContent([
      Content.multi([
        TextPart(geminiPrompt),
        DataPart('image/jpeg', jpegBytes),
      ]),
    ]);

    final jsonStr = extractJsonObject(response.text ?? '');
    if (jsonStr == null) return AnalysisResult.failure('AI 응답을 파싱할 수 없습니다');
    return AnalysisResult.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
  }
}

/// 응답 텍스트에서 가장 바깥 `{ ... }` 부분을 꺼낸다.
String? extractJsonObject(String text) {
  final start = text.indexOf('{');
  final end = text.lastIndexOf('}');
  if (start == -1 || end <= start) return null;
  return text.substring(start, end + 1);
}
