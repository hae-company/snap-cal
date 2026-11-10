# 보상형 광고 켜는 방법

광고 코드는 이미 앱에 들어 있습니다. **빌드할 때 모드만 바꾸면** 동작합니다.

## 규칙

- 무료 사용자가 **AI 분석 체험 3회를 다 쓴 뒤**에만 광고 버튼이 나옵니다.
- 광고를 **끝까지 보면 AI 분석 1회**를 받고, 바로 이어서 분석합니다. 중간에 닫으면 보상이 없습니다.
- **하루 최대 2회**. 날짜가 바뀌면 다시 2회.
- **구독자에게는 광고가 절대 보이지 않습니다.** 배너·전면 광고는 넣지 않습니다.
- 광고가 없을 때(재고 없음, 네트워크)는 안내 후 페이월에 그대로 남습니다. "AI 없이 사진과 함께 직접 기록하기"는 항상 남아 있습니다.
- 광고는 **결제가 켜져 있을 때만** 의미가 있습니다. 결제가 꺼져 있으면 모두 무료라 광고 버튼이 나올 일이 없습니다.

| 모드 | 빌드 옵션 | 동작 |
|---|---|---|
| 광고 없음 (기본) | 없음 | 광고 버튼 없음 |
| 테스트 광고 | `--dart-define=ADS=test` | 구글 테스트 광고. 돈이 오가지 않음 |
| 실제 광고 | `--dart-define=ADS=on` + 광고 단위 ID | AdMob 실제 광고 |

```bash
# 가짜 결제 + 테스트 광고로 흐름 확인
flutter run --dart-define=BILLING=mock --dart-define=ADS=test

# 실제 광고
flutter run --dart-define=BILLING=revenuecat ... \
  --dart-define=ADS=on \
  --dart-define=ADMOB_REWARDED_IOS=ca-app-pub-xxxx/yyyy \
  --dart-define=ADMOB_REWARDED_ANDROID=ca-app-pub-xxxx/zzzz
```

---

## 실제 광고 준비 (순서대로) 🙋

1. **AdMob 가입** → 앱 2개 등록 (iOS, Android) → 각각 **보상형 광고 단위** 만들기
2. **앱 ID 바꾸기** (지금은 구글 공개 테스트 ID가 들어 있음. 실제 ID로 바꾸지 않으면 실제 광고가 안 나옴)
   - iOS: `ios/Runner/Info.plist`의 `GADApplicationIdentifier`
   - Android: `android/app/src/main/AndroidManifest.xml`의 `com.google.android.gms.ads.APPLICATION_ID`
3. **app-ads.txt**: 스토어에 적은 개발자 웹사이트 최상위에 AdMob이 주는 `app-ads.txt` 파일을 올리기 (랜딩 페이지 주소 필요)
4. **스토어 개인정보 항목 수정**: App Store 개인정보 라벨, Google Play 데이터 보안 양식에 "광고 사용, 기기 식별자" 추가
5. **정산**: AdMob 결제 정보(세금·계좌) 등록. 광고 수익도 사업소득입니다.

### 선택 사항
- **iOS 추적 허용 팝업(ATT)**: 지금은 묻지 않습니다. 맞춤 광고가 아니라서 단가가 조금 낮지만 심사·개인정보 부담이 적습니다. 나중에 단가를 올리려면 팝업과 `NSUserTrackingUsageDescription`을 추가합니다.
- **유럽 동의 팝업(UMP)**: 한국만 출시하면 필요 없습니다. 해외 출시 때 추가합니다.

## 서버 단계에서 할 일 🤖
지금은 광고 보상 횟수를 **기기에서** 셉니다. 조작을 막으려면 AI 서버를 만들 때:
- AdMob **서버 측 검증(SSV)** 콜백 → Firebase 함수에서 보상 지급
- 하루 2회 한도와 보너스 횟수를 서버에서 관리

---

## 코드 구조

| 파일 | 내용 |
|---|---|
| `lib/data/ads/rewarded_ads.dart` | 광고 모드, 결과, 하루 한도(2회), 광고 없음·가짜·AdMob 구현 |
| `lib/data/billing/billing_providers.dart` | 보너스 횟수(`adRewardsProvider`), 광고 가능 여부(`canWatchAdProvider`), 남은 분석 횟수 = 체험 + 보너스 |
| `lib/features/paywall/paywall_screen.dart` | "광고 보고 1회 더 받기 (오늘 n/2)" 버튼 |
| `lib/app/config.dart` | `ADS`, 광고 단위 ID 빌드 옵션 |

남은 분석 횟수는 **체험(3회)을 먼저 쓰고**, 다 쓴 뒤 광고 보너스를 씁니다.
