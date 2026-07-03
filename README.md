# 하루 1분 💧

물과 영양제를 하루 1분으로 관리하는 Flutter 앱.

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)
![Version](https://img.shields.io/badge/version-2.6.0-orange)

---

## 주요 기능

- **물 섭취 기록** — 홈 화면 탭 한 번으로 기록, 목표량 진행률 시각화
- **영양제 관리** — 아침·점심·저녁·취침 시간대별 복용 스케줄
- **AI 사진 분석** — 영양제 통 사진 → Firebase AI(Gemini)가 이름·복용시간·팁 자동 입력
- **홈 위젯** — 물 섭취 현황을 홈 화면에서 바로 확인·추가
- **주간 스트릭** — 연속 달성일 추적
- **알림** — 복용 시간대별 푸시 알림
- **백업/복원** — 로컬 파일로 데이터 내보내기·불러오기
- **통계** — 월별 물·영양제 섭취 이력

## 기술 스택

| 영역 | 기술 |
|---|---|
| UI | Flutter 3, Riverpod |
| DB | SQLite (sqflite) |
| AI | Firebase AI (Gemini) |
| 알림 | flutter_local_notifications |
| 위젯 | home_widget |
| 백업 | archive, file_picker, share_plus |
| 분석 | Firebase Crashlytics |

## 빌드

```bash
flutter pub get
flutter build appbundle --release   # Android AAB
flutter build apk --release         # Android APK
```

## 버전 이력

| 버전 | 주요 변경 |
|---|---|
| 2.6.0 | 알림 액션 버튼(모두 복용·한 잔·스누즈), 오늘 물 기록 타임라인, 시간대 모두 체크, 전용 알림 아이콘, 접근성 라벨 |
| 2.5.1 | 예약 알림 미발화 수정(알림 리시버 등록), 기기 타임존 지원, 복용 팁 삭제 버그 수정, 고아 사진 정리 |
| 2.5.0 | AI 영양소 추출·상한(UL) 중복 경고 카드 |
| 2.4.1 | 위젯 물 추가 반응 즉시화 (낙관적 네이티브 업데이트) |
| 2.3.1 | Google Play 사진 권한 정책 준수 — Android Photo Picker 전환 |
| 2.3.0 | 추가·통계·설정 화면 리디자인 |
| 2.2.0 | 홈 UI/UX 리디자인 (시간대 그룹핑·주간 스트릭) |
| 2.1.0 | 백업/복원 기능 추가 |
| 2.0.1 | Crashlytics·AI JSON 모드·위젯 개선 |

## 개발자

**p2bble** · [GitHub](https://github.com/p2bble)
