<p align="center">
  <img src="assets/brand/tile.png" width="96" alt="스냅칼 로고">
</p>

<h1 align="center">스냅칼 (SnapCal)</h1>
<p align="center">찍으면 끝. 한식도 정확하게.</p>

음식 사진 한 장으로 칼로리와 탄단지를 기록하는 식단 앱입니다. Flutter로 iOS와 Android를 함께 만듭니다.

## 문서

| 문서 | 내용 |
|---|---|
| [구조도](docs/ARCHITECTURE.md) | 전체 구성, 앱 내부 계층, 화면 흐름, 사진 분석 흐름, 저장 데이터, 남은 단계 |
| [제품 설계서](docs/PRODUCT_DESIGN.md) | 수익 모델(구독), 기능 범위, 디자인 시스템, 법무 체크리스트 |

## 주요 기능

- 📷 사진으로 칼로리·탄단지 분석 (Gemini), 인분 단위 양 조절
- 🔍 한식 위주 음식 검색 (초성 검색), 최근·자주 먹은 음식 원탭 추가, 직접 입력
- 🍚 오늘 남은 칼로리 링, 끼니별 기록, 연속 기록일, 오늘의 한마디
- 📅 캘린더 기록 (목표 대비 색 표시), 지난 날짜에 추가, 기록 수정
- 📊 주간 리포트, 탄단지 비율, 체중 추이 그래프
- 💧 물 섭취, ⏰ 끼니 알림, 📤 CSV 내보내기, 🌙 다크 모드

## 개발

```bash
flutter pub get
flutter run                 # 실행
flutter test                # 테스트
```

- 폴더 이름에 한글이 있으면 `flutter analyze`가 멈추는 Flutter 도구 버그가 있습니다. 영문 경로의 심볼릭 링크에서 `dart analyze`를 실행하세요.
- 디자인 검수용 화면 캡처: `flutter test test/screenshots_test.dart --dart-define=SHOT_DIR=/절대/경로`
- 앱 아이콘 다시 만들기: `dart run flutter_launcher_icons` · 시작 화면: `dart run flutter_native_splash:create`

## 현재 상태

AI 분석은 아직 사용자가 설정에 Gemini API 키를 직접 넣는 방식입니다. 출시 전에 서버(Firebase Functions)로 옮깁니다. 자세한 순서는 [구조도 6장](docs/ARCHITECTURE.md#6-출시까지-남은-단계)을 보세요.
