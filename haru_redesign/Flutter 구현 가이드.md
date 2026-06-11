# 하루 1분 UI/UX 개선 — Flutter 구현 가이드

목업: `하루 1분 개선안.html` (같은 폴더) 기준. 수정 대상 파일과 함께 우선순위 순으로 정리했습니다.

---

## 1. 영양제 카드에 보이는 수정 진입점 ⚡ 최우선

**대상:** `lib/widgets/supplement_card.dart`, `lib/screens/home_screen.dart`

롱프레스가 유일한 수정/삭제 경로 — 발견 불가능합니다.

- 카드 우상단에 `⋯` 아이콘 추가 (24×24 시각, 터치 영역은 40×40 `InkWell`):
  탭하면 기존 `_showOptions` 바텀시트 호출. 롱프레스도 그대로 유지.
- 메뉴에 **알림 시간** 항목 추가 고려 (설정 화면까지 안 가도 되게).
- 첫 영양제 등록 직후 1회성 툴팁: `shared_preferences`에 `tip_card_menu_shown` 플래그,
  미표시 상태면 카드 위에 "⋯ 또는 길게 눌러 수정해요" 오버레이 (탭하면 dismiss).

## 2. 컵 용량 칩 어포던스

**대상:** `lib/widgets/water_tracker_widget.dart` (`_CupSizeSelector`)

- 라벨 `'250ml'` → `'한 잔 250ml'` + `Icon(Icons.keyboard_arrow_down, size: 16)`.
- 패딩 `4,10` → `9,12` (시각 높이 ~36px), `GestureDetector` → `InkWell` + `Material`로 교체.
  터치 영역 44px 확보: `InkWell`을 `SizedBox(height: 44)`로 감싸거나 `padding` 포함 영역 확대.

## 3. FAB 제거 + 빈 하단 활용

**대상:** `lib/screens/home_screen.dart`

- `FloatingActionButton.extended('영양제 추가')` 제거 →
  "오늘의 영양제" 섹션 헤더 우측에 원형 `+` 버튼 (32px 시각, 44px 터치).
  빈 상태일 때는 섹션 안 점선 카드 + "사진으로 등록" CTA (목업 ① "첫 실행" 아트보드).
- 하단 빈 공간에 **주간 스트릭 카드**: 7일 원형 점 (물+영양제 모두 = 채움+체크, 하나만 = 틴트,
  미달성 = 외곽선, 오늘 = 점선 테두리). 데이터는 기존 sqflite 일별 기록 주간 집계 쿼리 하나면
  됩니다. 탭하면 `StatsScreen`으로.

## 4. 시간대 그룹핑 (A안 — 확정)

**대상:** `home_screen.dart` (`_SupplementSection`)

- `mealTime` 기준 그룹핑: **현재 시간대 그룹을 틴트 배경 컨테이너로 강조** + "아침 · 지금" 라벨,
  나머지 시간대는 컴팩트 행(아이콘 + 라벨 + 요약 + 완료 체크/chevron).
- 현재 시간대 판정: 알림 설정의 시간대별 시각 기준 구간 매핑 (예: ~10시 아침, 10~15시 점심,
  15~21시 저녁, 21시~ 자기 전). `notification_provider`의 설정값 재사용.
- **상태 규칙** (목업 ① 아트보드 1~4 참조):
  - 강조 그룹은 하루 동안 현재 시간대를 따라 이동. 다른 시간대는 컴팩트 행.
  - 행 표시: 완료 = 초록 체크, 미완료 = chevron (탭하면 그 자리서 펼쳐 체크 가능).
  - 현재 시간대 모두 체크 시 강조 그룹 대신 "모두 완료!" 배너 (기존 패턴 재사용).
  - 영양제 0개(첫 실행): 섹션 안 점선 카드 + "사진으로 등록" CTA.

## 5. 탭 피드백

**대상:** `water_tracker_widget.dart`, `supplement_card.dart`

- `GestureDetector`+`Container` → `Material(color: ...) > InkWell(borderRadius: ...)`:
  리플 + 접근성 시맨틱이 무료로 따라옵니다.
- 물 기록 성공 시 `HapticFeedback.lightImpact()` + 버튼 위로 `+250ml` 플로팅 텍스트
  (Overlay + 450ms 위로 이동·페이드, `AnimationController` 하나).
- 영양제 체크 시에도 동일 햅틱. 누름 상태는 `InkWell` 기본 리플로 충분 — scale 효과까지
  원하면 `AnimatedScale(scale: pressed ? 0.97 : 1)`.

---

### 적용 순서 제안
2 (컵 칩, ~20분) → 5 (InkWell/햅틱) → 1 (⋯ 메뉴 + 툴팁) → 3 (FAB/스트릭) → 4 (시간대 그룹핑)

**A안 확정.** 목업 ① 섹션의 4가지 상태(아침 기본 · 저녁 강조 이동 · 모두 완료 · 첫 실행)를
구현 기준으로 사용하세요. B안은 참고용으로 ② 섹션에 남겨뒀습니다.
