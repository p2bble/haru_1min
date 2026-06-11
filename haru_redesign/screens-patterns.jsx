// @ds-adherence-ignore -- 하루 1분 목업 (외부 앱 컨설팅용)
// 패턴: 컵 용량 칩 · 카드 ⋯ 메뉴 + 툴팁 · 탭 피드백

function HPatWrap({ children, title, w = 400 }) {
  return (
    <div style={{
      width: '100%', boxSizing: 'border-box', minHeight: '100%', padding: 20, background: HM.bg,
      fontFamily: "'Pretendard Variable', Pretendard, sans-serif", color: HM.ink,
    }}>
      <div style={{ fontSize: 12, fontWeight: 700, color: HM.muted, marginBottom: 14, letterSpacing: 0.3 }}>{title}</div>
      {children}
    </div>
  );
}

// ════════════════════════════════════════════════════════════
// 컵 용량 칩 — Before / After
// ════════════════════════════════════════════════════════════
function HPatCupChip() {
  return (
    <HPatWrap title="컵 용량 선택 칩">
      <div style={{ display: 'flex', gap: 14 }}>
        {/* before */}
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 12, fontWeight: 800, color: '#D95454', marginBottom: 8 }}>BEFORE</div>
          <div style={{ background: HM.surface, borderRadius: 16, padding: 14, display: 'flex', alignItems: 'center', gap: 8 }}>
            <Icon name="water_drop" size={17} fill={1} color={HM.primary} />
            <span style={{ fontSize: 14, fontWeight: 700 }}>오늘의 물</span>
            <span style={{ marginLeft: 'auto', background: HM.primaryTint, color: HM.primaryDark, borderRadius: 999, padding: '4px 10px', fontSize: 11, fontWeight: 600 }}>250ml</span>
          </div>
          <div style={{ fontSize: 11.5, color: HM.muted, marginTop: 8, lineHeight: 1.55 }}>
            정적 라벨처럼 보이고 터치 영역 ~28px — 눌러볼 생각이 안 들어요
          </div>
        </div>
        {/* after */}
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 12, fontWeight: 800, color: '#2E8B57', marginBottom: 8 }}>AFTER</div>
          <div style={{ background: HM.surface, borderRadius: 16, padding: 14, display: 'flex', alignItems: 'center', gap: 8 }}>
            <Icon name="water_drop" size={17} fill={1} color={HM.primary} />
            <span style={{ fontSize: 14, fontWeight: 700, whiteSpace: 'nowrap' }}>오늘의 물</span>
            <span style={{ marginLeft: 'auto', display: 'inline-flex', alignItems: 'center', gap: 3, background: HM.primaryTint, color: HM.primaryDark, borderRadius: 999, padding: '9px 10px 9px 12px', fontSize: 12.5, fontWeight: 700, whiteSpace: 'nowrap' }}>
              한 잔 250ml<Icon name="keyboard_arrow_down" size={15} weight={600} />
            </span>
          </div>
          <div style={{ fontSize: 11.5, color: HM.muted, marginTop: 8, lineHeight: 1.55 }}>
            "한 잔" 레이블 + ▾ 글리프 + 높이 36px(터치 44px) — 버튼임이 분명해져요
          </div>
        </div>
      </div>
    </HPatWrap>
  );
}

// ════════════════════════════════════════════════════════════
// 카드 ⋯ 메뉴 — 롱프레스의 보이는 대안
// ════════════════════════════════════════════════════════════
function HPatCardMenu() {
  return (
    <HPatWrap title="영양제 카드 수정·삭제 진입점">
      <div style={{ display: 'flex', gap: 16, alignItems: 'flex-start', marginTop: 34 }}>
        <div style={{ width: 124, position: 'relative' }}>
          <SuppCard name="오메가3" time="아침" taken={false} />
          {/* 첫 사용 툴팁 */}
          <div style={{ position: 'absolute', top: -34, right: -56, background: HM.ink, color: '#fff', fontSize: 11, fontWeight: 600, borderRadius: 8, padding: '6px 10px', whiteSpace: 'nowrap' }}>
            ⋯ 또는 길게 눌러 수정해요
            <div style={{ position: 'absolute', bottom: -4, left: 60, width: 8, height: 8, background: HM.ink, transform: 'rotate(45deg)' }}></div>
          </div>
        </div>
        {/* 열린 메뉴 */}
        <div style={{ background: HM.surface, borderRadius: 14, boxShadow: '0 8px 28px rgba(26,26,46,0.16)', padding: 6, width: 150, marginTop: 14 }}>
          {[
            { icon: 'edit', label: '수정', color: HM.suppDark },
            { icon: 'notifications', label: '알림 시간', color: HM.primaryDark },
            { icon: 'delete', label: '삭제', color: '#D95454' },
          ].map(function (m, i) {
            return (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 9, padding: '9px 10px', borderRadius: 9 }}>
                <Icon name={m.icon} size={16} color={m.color} />
                <span style={{ fontSize: 13, fontWeight: 600, color: m.label === '삭제' ? '#D95454' : HM.ink }}>{m.label}</span>
              </div>
            );
          })}
        </div>
      </div>
      <div style={{ marginTop: 16, fontSize: 12, color: HM.muted, lineHeight: 1.65 }}>
        롱프레스는 유지하되 <b style={{ color: HM.ink }}>카드 우상단 ⋯이 보이는 진입점</b>이 됩니다.<br />
        첫 영양제 등록 직후 1회만 툴팁 노출 (shared_preferences 플래그).
      </div>
    </HPatWrap>
  );
}

// ════════════════════════════════════════════════════════════
// 탭 피드백 — InkWell + 햅틱
// ════════════════════════════════════════════════════════════
function HPatFeedback() {
  return (
    <HPatWrap title="탭 피드백 (물 한 잔 기록)">
      <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
        {/* pressed state */}
        <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
          <div style={{
            flex: 1, height: 50, borderRadius: 14, background: HM.primaryDark,
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
            color: '#fff', fontSize: 15, fontWeight: 800, transform: 'scale(0.97)',
          }}>
            <Icon name="add" size={18} weight={700} />한 잔 마셨어요
          </div>
          <span style={{ fontSize: 11.5, color: HM.muted, width: 110, lineHeight: 1.5 }}>눌림: 리플 + scale 0.97 + 살짝 어두운 톤</span>
        </div>
        {/* +250 floating feedback */}
        <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
          <div style={{ flex: 1, position: 'relative', height: 56 }}>
            <div style={{
              position: 'absolute', left: '50%', top: 0, transform: 'translateX(-50%)',
              color: HM.primaryDark, fontSize: 19, fontWeight: 800,
            }}>+250ml</div>
            <div style={{ position: 'absolute', left: '50%', bottom: 0, transform: 'translateX(-50%)', fontSize: 11, color: HM.faint }}>위로 떠오르며 사라짐 (450ms)</div>
          </div>
          <span style={{ fontSize: 11.5, color: HM.muted, width: 110, lineHeight: 1.5 }}>기록 직후: +250ml 플로팅 + 가벼운 햅틱</span>
        </div>
      </div>
      <div style={{ marginTop: 14, fontSize: 12, color: HM.muted, lineHeight: 1.65 }}>
        GestureDetector+Container → <b style={{ color: HM.ink }}>Material+InkWell</b>로 교체 (리플·시맨틱 무료 획득),<br />
        기록 성공 시 <b style={{ color: HM.ink }}>HapticFeedback.lightImpact()</b>.
      </div>
    </HPatWrap>
  );
}

Object.assign(window, { HPatCupChip, HPatCardMenu, HPatFeedback });
