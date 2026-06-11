// @ds-adherence-ignore -- 하루 1분 목업 (외부 앱 컨설팅용)
// A안 상태 디테일: 저녁 시점 · 모두 완료 · 첫 실행(빈 상태)

// 시간대 컴팩트 행
function SlotRow({ icon, label, desc, done, now }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 10, background: HM.surface,
      borderRadius: 14, padding: '11px 14px', boxShadow: '0 2px 10px rgba(79,195,247,0.06)',
    }}>
      <Icon name={icon} size={18} color={HM.muted} />
      <span style={{ fontSize: 13.5, fontWeight: 700 }}>{label}</span>
      <span style={{ fontSize: 12.5, color: HM.muted }}>{desc}</span>
      {done ? <Icon name="check_circle" size={17} fill={1} color={HM.taken} style={{ marginLeft: 'auto' }} />
        : <Icon name="chevron_right" size={18} color={HM.faint} style={{ marginLeft: 'auto' }} />}
    </div>
  );
}

// 강조 그룹 (지금 시간대)
function NowGroup({ icon, label, sub, children }) {
  return (
    <div style={{ background: HM.suppTint, borderRadius: 18, padding: 12 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '0 4px 10px' }}>
        <Icon name={icon} size={15} fill={1} color={HM.suppDark} />
        <span style={{ fontSize: 13, fontWeight: 800, color: HM.suppDark }}>{label} · 지금</span>
        <span style={{ fontSize: 12, color: HM.suppDark, opacity: 0.7 }}>{sub}</span>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8 }}>{children}</div>
    </div>
  );
}

function SuppHeaderRow({ count, total }) {
  return (
    <SecH icon="pill" iconColor={HM.supp} title="오늘의 영양제" right={[
      <Pill key="c" label={`${count} / ${total}`} bg={`${HM.supp}1F`} color={HM.suppDark} />,
      <span key="a" style={{ width: 32, height: 32, borderRadius: 16, background: HM.suppTint, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <Icon name="add" size={18} color={HM.suppDark} weight={600} />
      </span>,
    ]} />
  );
}

// ════════════════════════════════════════════════════════════
// 저녁 시점 — 강조 그룹이 시간대를 따라 이동
// ════════════════════════════════════════════════════════════
function HaruAEvening() {
  return (
    <Phone>
      <div style={{ flex: 1, padding: '6px 18px 14px', display: 'flex', flexDirection: 'column', gap: 14, overflow: 'hidden' }}>
        <HaruHeader />
        <WaterCard ring={144} percent={0.9} value="1800" />
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          <SuppHeaderRow count={3} total={4} />
          <SlotRow icon="light_mode" label="아침" desc="비타민C · 오메가3" done={true} />
          <NowGroup icon="wb_twilight" label="저녁" sub="1개 남았어요">
            <SuppCard name="마그네슘" taken={false} />
          </NowGroup>
          <SlotRow icon="bedtime" label="자기 전" desc="유산균" done={true} />
        </div>
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
// 모두 완료 — 강조 그룹 대신 완료 배너, 스트릭 오늘 채워짐
// ════════════════════════════════════════════════════════════
function HaruADone() {
  return (
    <Phone>
      <div style={{ flex: 1, padding: '6px 18px 14px', display: 'flex', flexDirection: 'column', gap: 14, overflow: 'hidden' }}>
        <HaruHeader />
        <WaterCard ring={138} percent={1} value="2000" done={true} />
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          <SuppHeaderRow count={4} total={4} />
          <div style={{
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 7,
            background: 'rgba(76,175,80,0.10)', borderRadius: 14, padding: '13px 0',
          }}>
            <Icon name="check_circle" size={17} fill={1} color={HM.taken} />
            <span style={{ fontSize: 13.5, fontWeight: 700, color: HM.taken }}>오늘 영양제 모두 완료!</span>
          </div>
          <SlotRow icon="light_mode" label="아침" desc="비타민C · 오메가3" done={true} />
          <SlotRow icon="wb_twilight" label="저녁" desc="마그네슘" done={true} />
          <SlotRow icon="bedtime" label="자기 전" desc="유산균" done={true} />
        </div>
        <HCard pad={16} style={{ marginTop: 'auto' }}>
          <div style={{ display: 'flex', alignItems: 'center', marginBottom: 12 }}>
            <span style={{ fontSize: 14, fontWeight: 700 }}>이번 주 기록</span>
            <span style={{ marginLeft: 'auto', fontSize: 12, fontWeight: 600, color: HM.primaryDark }}>5일 달성!</span>
          </div>
          <WeekStreak days={[2, 2, 1, 2, 0, 2, 2]} />
        </HCard>
      </div>
    </Phone>
  );
}

// ════════════════════════════════════════════════════════════
// 첫 실행 — 영양제 0개 (FAB 제거 후의 빈 상태 CTA)
// ════════════════════════════════════════════════════════════
function HaruAEmpty() {
  return (
    <Phone>
      <div style={{ flex: 1, padding: '6px 18px 14px', display: 'flex', flexDirection: 'column', gap: 14, overflow: 'hidden' }}>
        <HaruHeader />
        <WaterCard ring={144} percent={0.125} value="250" />
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10, flex: 1 }}>
          <SecH icon="pill" iconColor={HM.supp} title="오늘의 영양제" />
          <div style={{
            background: HM.surface, borderRadius: 18, border: `1.5px dashed ${HM.line}`,
            padding: '26px 20px', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
          }}>
            <div style={{ width: 64, height: 64, borderRadius: '50%', background: HM.suppTint, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Icon name="pill" size={30} fill={1} color={HM.supp} />
            </div>
            <div style={{ fontSize: 15, fontWeight: 800, marginTop: 8 }}>드시는 영양제가 있나요?</div>
            <div style={{ fontSize: 12.5, color: HM.muted, textAlign: 'center', lineHeight: 1.6 }}>
              사진으로 등록하면 매일 체크만 하면 돼요
            </div>
            <div style={{
              display: 'inline-flex', alignItems: 'center', gap: 6, height: 46, padding: '0 22px',
              borderRadius: 999, background: HM.supp, color: '#fff', fontSize: 14, fontWeight: 800, marginTop: 12,
            }}>
              <Icon name="photo_camera" size={17} />사진으로 등록
            </div>
          </div>
        </div>
        <HCard pad={16}>
          <div style={{ display: 'flex', alignItems: 'center', marginBottom: 12 }}>
            <span style={{ fontSize: 14, fontWeight: 700 }}>이번 주 기록</span>
            <span style={{ marginLeft: 'auto', fontSize: 12, fontWeight: 600, color: HM.primaryDark }}>시작이 반이에요</span>
          </div>
          <WeekStreak days={[0, 0, 0, 0, 0, 1, -1]} />
        </HCard>
      </div>
    </Phone>
  );
}

Object.assign(window, { HaruAEvening, HaruADone, HaruAEmpty, SlotRow, NowGroup });
