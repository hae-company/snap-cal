const geminiPrompt = '''
이 음식 사진을 분석해주세요. 반드시 아래 JSON 형식으로만 응답하세요. 다른 텍스트 없이 JSON만 출력하세요.

{
  "food_name": "음식 이름 (한국어)",
  "calories": 예상 칼로리 (숫자만),
  "carbs": 탄수화물 g (숫자만),
  "protein": 단백질 g (숫자만),
  "fat": 지방 g (숫자만),
  "confidence": "high" 또는 "medium" 또는 "low",
  "description": "한 줄 설명"
}

음식이 아닌 사진이면: { "error": "음식이 아닙니다" }
''';
