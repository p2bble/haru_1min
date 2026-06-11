// @ds-adherence-ignore -- 하루 1분 목업 (외부 앱 컨설팅용)
// 홈 개선 A안 / B안

function HaruHeader() {
  return (
    <div style={{ display: 'flex', alignItems: 'center', padding: '6px 2px 0' }}>
      <div>
        <div style={{ fontSize: 21, fontWeight: 800 }}>하루 1분</div>
        <div style={{ fontSize: 12, color: HM.muted, marginTop: 1 }}>6월 11일 목요일</div>
      </div>
      <div style={{ marginLeft: 'auto', display: 'flex', gap: 14 }}>
        <Icon name="bar_chart" size={22} color={HM.muted} />
        <Icon name="settings" size={22} color={HM.muted} />
      </div>
    </div>
  );
}

// 개선된 물 카드 (공통): 컵 칩에 ▾ + 44px 터치영역, 버튼 InkWell 느낌
function WaterCard({ ring = 150, percent = 0.75, value = '1500', done = false }) {
  return (
    <HCard>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <Icon name="water_drop" size={19} fill={1} color={HM.primary} />
        <span style={{ fontSize: 16, fontWeight: 700 }}>오늘의 물</span>
        {/* 컵 용량: 버튼임이 보이는 칩 */}
        <span style={{
          marginLeft: 'auto', display: 'inline-flex', alignItems: 'center', gap: 3,
          background: HM.primaryTint, color: HM.primaryDark, borderRadius: 999,
          padding: '9px 12px 9px 14px', fontSize: 13, fontWeight: 700,
        }}>
          한 잔 250ml<Icon name="keyboard_arrow_down" size={16} weight={600} />
        </span>
      </div>
      <div style={{ display: 'flex', justifyContent: 'center', padding: '16px 0' }}>
        <WaterRing size={ring} percent={percent} value={value} />
      </div>
      <div style={{ display: 'flex', gap: 10 }}>
        <div style={{
          flex: 1, height: 50, borderRadius: 14, background: HM.primary, color: '#fff',
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
          fontSize: 15.5, fontWeight: 800,
        }}>
          <Icon name="add" size={19} weight={700} />한 잔 마셨어요
        </div>
        <div style={{
          width: 50, height: 50, borderRadius: 14, background: 'rgba(107,114,128,0.10)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', color: HM.muted,
        }}>
          <Icon name="undo" size={20} />
        </div>
      </div>
      {done ? (
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6, background: HM.primaryTint, borderRadius: 999, padding: '8px 0', marginTop: 12 }}>
          <Icon name="celebration" size={15} color={HM.primaryDark} />
          <span style={{ fontSize: 12.5, fontWeight: 700, color: HM.primaryDark }}>오늘 목표 달성!</span>
        </div>
      ) : null}
    </HCard>
  );
}

// ════════════════════════════════════════════════════════════
// A안 · 시간대 그룹핑 — "지금 뭘 먹어야 하지"가 즉답
// ════════════════════════════════════════════════════════════
function HaruHomeA() {
  return (
    <Phone>
      <div style={{ flex: 1, padding: '6px 18px 14px', display: 'flex', flexDirection: 'column', gap: 14, overflow: 'hidden' }}>
        <HaruHeader />
        <WaterCard ring={144} />

        {/* 영양제 — 시간대 그룹, FAB 대신 헤더 + */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          <SecH icon="pill" iconColor={HM.supp} title="오늘의 영양제" right={[
            <Pill key="c" label="2 / 4" bg={`${HM.supp}1F`} color={HM.suppDark} />,
            <span key="a" style={{ width: 32, height: 32, borderRadius: 16, background: HM.suppTint, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Icon name="add" size={18} color={HM.suppDark} weight={600} />
            </span>,
          ]} />

          {/* 지금 시간대 — 강조 그룹 */}
          <div style={{ background: HM.suppTint, borderRadius: 18, padding: 12 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '0 4px 10px' }}>
              <Icon name="light_mode" size={15} fill={1} color={HM.suppDark} />
              <span style={{ fontSize: 13, fontWeight: 800, color: HM.suppDark }}>아침 · 지금</span>
              <span style={{ fontSize: 12, color: HM.suppDark, opacity: 0.7 }}>2개 중 1개 남았어요</span>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8 }}>
              <SuppCard name="비타민C" taken={true} />
              <SuppCard name="오메가3" taken={false} />
            </div>
          </div>

          {/* 다음 시간대 — 컴팩트 행 */}
          {[
            { icon: 'wb_twilight', label: '저녁', desc: '마그네슘', done: false },
            { icon: 'bedtime', label: '자기 전', desc: '유산균', done: true },
          ].map(function (g, i) {
            return (
              <div key={i} style={{
                display: 'flex', alignItems: 'center', gap: 10, background: HM.surface,
                borderRadius: 14, padding: '11px 14px', boxShadow: '0 2px 10px rgba(79,195,247,0.06)',
              }}>
                <Icon name={g.icon} size={18} color={HM.muted} />
                <span style={{ fontSize: 13.5, fontWeight: 700 }}>{g.label}</span>
                <span style={{ fontSize: 12.5, color: HM.muted }}>{g.desc}</span>
                {g.done ? <Icon name="check_circle" size={17} fill={1} color={HM.taken} style={{ marginLeft: 'auto' }} />
                  : <Icon name="chevron_right" size={18} color={HM.faint} style={{ marginLeft: 'auto' }} />}
              </div>
            );
          })}
        </div>

        {/* 빈 하단 → 주간 스트릭 */}
        <HCard pad={16} style={{ marginTop: 'auto' }}>
          <div style={{ display: 'flex', alignItems: 'center', marginBottom: 12 }}>
            <span style={{ fontSize: 14, fontWeight: 700 }}>이번 주 기록</span>
            <span style={{ marginLeft: 'auto', fontSize: 12, fontWeight: 600, color: HM.primaryDark }}>4일 달성 중</span>
          </div>
          <WeekStreak />
        </HCard>
      </div>
    </Phone>
  );
}

// ════════════════════════════════════════════════════════════
// B안 · 그리드 유지 + 시간대 필터 칩 + 인라인 스트릭
// ════════════════════════════════════════════════════════════
function HaruHomeB() {
  return (
    <Phone>
      <div style={{ flex: 1, padding: '6px 18px 14px', display: 'flex', flexDirection: 'column', gap: 14, overflow: 'hidden' }}>
        <HaruHeader />

        {/* 인라인 스트릭 — 헤더 바로 아래 한 줄 */}
        <HCard pad={12}>
          <WeekStreak compact={true} />
        </HCard>

        <WaterCard ring={132} />

        <div style={{ display: 'flex', flexDirection: 'column', gap: 10, flex: 1 }}>
          <SecH icon="pill" iconColor={HM.supp} title="오늘의 영양제" right={[
            <span key="a" style={{ width: 32, height: 32, borderRadius: 16, background: HM.suppTint, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Icon name="add" size={18} color={HM.suppDark} weight={600} />
            </span>,
          ]} />

          {/* 시간대 필터 칩 — 현재 시간대 자동 선택 */}
          <div style={{ display: 'flex', gap: 7 }}>
            {['전체', '아침', '저녁', '자기 전'].map(function (f, i) {
              const on = i === 1;
              return (
                <span key={i} style={{
                  padding: '8px 13px', borderRadius: 999, fontSize: 12.5, fontWeight: 700,
                  background: on ? HM.suppDark : HM.surface,
                  color: on ? '#fff' : HM.muted,
                  border: `1px solid ${on ? HM.suppDark : HM.line}`,
                  display: 'inline-flex', alignItems: 'center', gap: 4,
                }}>
                  {on ? <Icon name="light_mode" size={13} fill={1} /> : null}{f}
                </span>
              );
            })}
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 9 }}>
            <SuppCard name="비타민C" time="아침" taken={true} />
            <SuppCard name="오메가3" time="아침" taken={false} />
          </div>

          <div style={{
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 7,
            background: 'rgba(76,175,80,0.09)', borderRadius: 14, padding: '11px 0',
          }}>
            <Icon name="celebration" size={16} color={HM.taken} />
            <span style={{ fontSize: 13, fontWeight: 700, color: HM.taken }}>아침 영양제 1개만 더 먹으면 완료!</span>
          </div>
        </div>
      </div>
    </Phone>
  );
}

Object.assign(window, { HaruHeader, WaterCard, HaruHomeA, HaruHomeB });
