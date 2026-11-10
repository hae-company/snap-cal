# 스냅칼 구조도

> 2026-11-10 기준 · 코드: `lib/` · 기획: [PRODUCT_DESIGN.md](PRODUCT_DESIGN.md)
>
> **범례**: ✅ 구현됨 · 🚧 다음 작업 · 💤 나중에

---

## 1. 전체 구성 (출시 목표)

로그인 화면은 없습니다. 식단 기록은 **폰에만** 저장하고, 서버는 AI 분석과 구독 확인에만 씁니다.

```mermaid
flowchart TB
  subgraph Phone["📱 스냅칼 앱 (Flutter · iOS / Android)"]
    direction LR
    UI["화면<br>오늘 · 기록 · 촬영 · 리포트 · MY"]
    Local[("기기 저장소 ✅<br>식단 · 물 · 체중 · 설정")]
    Foods[("내장 음식 목록 ✅<br>한식 185개")]
    Noti["끼니 알림 ✅<br>로컬 알림"]
    UI --- Local
    UI --- Foods
    UI --- Noti
  end

  subgraph Server["☁️ 서버 🚧"]
    direction LR
    subgraph Firebase["Firebase (서울 리전)"]
      direction TB
      Anon["익명 ID<br>사용자에게 안 보임"]
      Check["App Check<br>정식 앱 요청만 허용"]
      Fn["analyzeFood 함수<br>사용량 제한 · 구독 확인"]
      Usage[("사용량 · 구독 상태")]
      Check --> Fn
      Fn --- Usage
    end
    RC["💳 RevenueCat<br>구독 · 체험 · 복원"]
  end

  subgraph External["외부 서비스"]
    direction LR
    Gemini["🤖 Gemini<br>Vertex AI · 유료"]
    Stores["App Store · Google Play<br>실제 결제"]
  end

  UI -- "사진 분석 요청" --> Check
  UI -. "첫 실행 시 1회" .-> Anon
  UI -- "구독 결제 · 복원" --> RC
  RC -- "구독 변경 알림" --> Fn
  Fn -- "사진 + 프롬프트" --> Gemini
  RC --- Stores
```

| 구성 요소 | 하는 일 | 상태 |
|---|---|---|
| 기기 저장소 | 식단 기록, 물, 체중, 목표, 알림 설정 | ✅ |
| 내장 음식 목록 | 검색해서 기록하기 (초성 검색 지원) | ✅ 식약처 DB로 교체 예정 |
| 끼니 알림 | 아침·점심·저녁 기록 알림 (서버 없이 폰에서) | ✅ |
| Gemini 호출 | **현재는 앱이 사용자 API 키로 직접 호출** | 🚧 서버로 이동 |
| Firebase 익명 ID | 서버가 사용량을 세기 위한 보이지 않는 ID | 🚧 |
| RevenueCat | 구독 결제, 체험, 복원 | ✅ 앱 코드 완료 (결제 꺼짐으로 대기) → [BILLING.md](BILLING.md) |
| 백업 파일 | 폰 교체 시 기록 옮기기 (로그인 대신) | 🚧 |

---

## 2. 앱 내부 계층

화면은 저장소(Repository) **인터페이스만** 봅니다. 그래서 Gemini 직접 호출을 서버 호출로 바꿔도 화면 코드는 바뀌지 않습니다.

```mermaid
flowchart TB
  subgraph L1["화면 · features/"]
    direction LR
    Today["today<br>오늘"]
    Log["log<br>기록 캘린더"]
    Capture["capture<br>촬영 · 결과"]
    Entry["food_entry<br>검색 · 수정"]
    Report["report<br>리포트 · 체중"]
    My["my<br>목표 · 알림 · 데이터"]
    Onb["onboarding"]
  end

  subgraph L2["상태 · data/providers.dart (Riverpod)"]
    direction LR
    P1["goals · themeMode<br>onboarded · reminders"]
    P2["mealsInRange · mealsByDate<br>monthCalories · streak · quickFoods"]
    P3["water · weights<br>targetWeight"]
    P4["mealActions<br>추가 · 수정 · 삭제 후 새로고침"]
  end

  subgraph L3["저장소 · data/repositories/"]
    direction LR
    R1["MealRepository"]
    R2["SettingsRepository"]
    R3["BodyLogRepository"]
    R4["FoodCatalogRepository"]
    R5["FoodAnalysisRepository"]
  end

  subgraph L4["바깥 세계"]
    direction LR
    SP[("SharedPreferences")]
    Asset[("assets/data<br>korean_foods.json")]
    AI["Gemini<br>🚧 → Firebase 함수"]
    OS["알림 · 공유 시트<br>data/services/"]
  end

  L1 --> L2 --> L3
  R1 --> SP
  R2 --> SP
  R3 --> SP
  R4 --> Asset
  R5 --> AI
  L2 --> OS

  Shared["shared/ · app/theme/<br>공용 위젯 · 디자인 토큰"] -.-> L1
  Core["core/<br>칼로리 계산 · 오늘의 한마디 · 날짜"] -.-> L2
```

### 폴더 지도

| 폴더 | 내용 |
|---|---|
| `lib/app/` | 앱 시작점, 화면 이동(`router.dart`), 디자인 토큰(`theme/`) |
| `lib/core/` | 화면과 무관한 순수 로직: 끼니 판별, TDEE 계산, 오늘의 한마디, 날짜 키 |
| `lib/data/models/` | `FoodRecord`(기록), `FoodItem`(음식 목록), `AnalysisResult`(AI 결과) |
| `lib/data/repositories/` | 저장·조회 인터페이스와 구현 |
| `lib/data/services/` | 끼니 알림 예약, CSV 내보내기 |
| `lib/data/billing/` | 구독 결제 (결제 꺼짐 / 가짜 / RevenueCat), 이용 범위, 무료 분석 횟수 |
| `lib/features/paywall/` | 페이월, 잠금 확인 함수, 잠금 표시, MY 구독 카드 |
| `lib/features/` | 화면별 폴더 |
| `lib/shared/` | 여러 화면이 같이 쓰는 위젯 (칼로리 링, 끼니 카드, 입력 대화상자 등) |
| `assets/brand/` | 로고·아이콘 원본 (`mark_source.js`가 좌표 원본) |
| `test/` | 로직·저장소·화면 흐름 테스트, 디자인 검수용 스크린샷 |

---

## 3. 화면 흐름

```mermaid
flowchart LR
  Start(["앱 실행"]) --> Q{"온보딩<br>완료?"}
  Q -- 아니요 --> Onb["환영 → 성별 → 신체 → 활동량 → 맞춤 목표"]
  Onb --> Pay["💳 페이월<br>결제 켜졌을 때만"]
  Pay --> Shell
  Q -- 예 --> Shell

  subgraph Shell["하단 탭"]
    direction LR
    T1["오늘"]
    T2["기록"]
    Cam(("📷"))
    T3["리포트"]
    T4["MY"]
  end

  Cam --> Capture["촬영 (전체 화면)"]
  Capture -- "사진 선택" --> Scan["AI 분석 중<br>스캔 애니메이션"]
  Scan --> Result["결과<br>양 조절 · 숫자 수정 · 끼니 선택"]
  Capture -- "검색" --> Add
  T1 -- "끼니별 사진/검색" --> Capture
  T1 -- "검색해서 추가" --> Add["음식 검색<br>최근 · 자주 · 분류 · 직접 입력"]
  T2 -- "지난 날짜에 추가" --> Add
  T1 -- "음식 누르기" --> Edit["수정 시트<br>양 · 영양소 · 끼니 · 삭제"]
  T2 -- "음식 누르기" --> Edit
  Result --> Saved[("기록 저장")]
  Add --> Saved
  Edit --> Saved
```

---

## 4. 사진 분석 흐름

### 지금 (출시 불가 상태)

```mermaid
sequenceDiagram
  participant U as 앱
  participant G as Gemini API

  U->>U: 사진 촬영 · 1024px로 축소
  U->>G: 사용자가 입력한 API 키 + 사진 + 프롬프트
  G-->>U: 음식 1개 JSON
  U->>U: 결과 화면 → 기기에 저장
```

### 바꿀 구조 🚧

```mermaid
sequenceDiagram
  participant U as 앱
  participant F as analyzeFood 함수
  participant D as 사용량·구독 기록
  participant G as Gemini (Vertex AI)

  U->>F: 사진 + 익명 ID + App Check 토큰
  F->>D: 구독 중인가? 오늘 몇 번 썼나?
  alt 무료 체험 소진 또는 하루 한도 초과
    F-->>U: 거절 → 페이월 표시
  else 사용 가능
    F->>G: 사진 + 프롬프트 (응답 형식 강제)
    G-->>F: 음식별 목록 (이름 · 양 · 칼로리 · 탄단지)
    F->>F: 음식 DB로 보정
    F->>D: 사용량 +1
    F-->>U: 보정된 결과
  end
  U->>U: 결과 화면 → 기기에 저장
```

- API 키는 서버에만 있고 앱에는 없습니다.
- 사진은 분석에만 쓰고 서버에 저장하지 않습니다.
- 무료 사용자는 체험 3회, 프리미엄은 하루 30회까지입니다.

---

## 5. 기기에 저장되는 데이터

모두 `SharedPreferences`에 저장합니다. 키 이름은 이전 버전과 같아서 업데이트해도 기록이 유지됩니다.

| 키 | 형식 | 내용 |
|---|---|---|
| `food_records` | JSON 배열 | 식단 기록 (`FoodRecord`: 날짜, 끼니, 음식, 칼로리·탄단지, 인분, 출처, 사진 경로) |
| `daily_goal`, `carbs_goal`, `protein_goal`, `fat_goal` | 정수 | 하루 목표 |
| `water_log` | JSON 객체 | 날짜 → 마신 물(ml) |
| `water_goal` | 정수 | 물 목표 (기본 2,000ml) |
| `weight_log` | JSON 객체 | 날짜 → 체중(kg) |
| `target_weight` | 실수 | 목표 체중 |
| `meal_reminders` | JSON 배열 | 끼니 알림 (켜짐, 시각) |
| `theme_mode` | 문자열 | 시스템 / 라이트 / 다크 |
| `onboarded` | 참/거짓 | 온보딩 완료 여부 |
| `gemini_api_key` | 문자열 | 🚧 서버 전환 후 삭제 |

```mermaid
erDiagram
  FOOD_RECORD {
    int id
    string date "yyyy-MM-dd"
    string meal_type "breakfast · lunch · dinner · snack"
    string food_name
    int calories
    int carbs
    int protein
    int fat
    double servings "1인분 대비 배수"
    string source "ai · db · manual"
    string image_path
    datetime created_at
  }
  FOOD_ITEM {
    string id
    string name
    string category
    string serving "1공기 등"
    int grams
    int kcal
    string aliases "별칭 목록"
  }
  FOOD_ITEM ||..o{ FOOD_RECORD : "검색해서 추가"
```

---

## 6. 출시까지 남은 단계

```mermaid
flowchart LR
  A["✅ 기반 정리<br>구조 · 상태관리 · 디자인 토큰"] --> B["✅ 디자인 · 로고"]
  B --> C["✅ 기능 추가<br>검색 · 수정 · 물 · 체중 · 알림 · CSV"]
  C --> D["🚧 AI 서버<br>키 숨기기 · 사용량 제한 · 음식별 인식"]
  D --> E["✅ 구독 코드 · 페이월 · 체험 3회<br>🚧 상품 등록 · 키 연결"]
  E --> F["🚧 백업 파일<br>저장 · 불러오기"]
  F --> G["🚧 출시 준비<br>약관 · 스토어 등록 · 정확도 측정"]
  G --> H(["🚀 출시"])
```

| 단계 | 필요한 것 (직접 준비) |
|---|---|
| AI 서버 | Firebase 프로젝트 + 결제 수단, `firebase login` |
| 구독 | Apple 개발자 계정($99/년), Google Play 개발자 계정($25), RevenueCat 계정 |
| 출시 준비 | 사업자등록, 개인정보처리방침 게시용 웹 주소 |
