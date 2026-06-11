// @ds-adherence-ignore -- 하루 1분 목업 (외부 앱 컨설팅용)
// 영양제 추가 화면: 초기 상태 · AI 분석 완료 상태

function FieldLabel({ children }) {
  return <div style={{ fontSize: 13.5, fontWeight: 700, marginBottom: 8 }}>{children}</div>;
}
function TextInput({ value, hint, aiTag }) {
  return (
    <div style={{ position: 'relative' }}>
      <div style={{
        background: HM.surface, borderRadius: 12, padding: '14px 16px',
        fontSize: 14.5, fontWeight: value ? 600 : 400,
        color: value ? HM.ink : HM.faint,
        border: aiTag ? `1.5px solid ${HM.supp}` : `1.5px solid transparent`,
      }}>{value || hint}</div>
      {aiTag ? (
        <span style={{
          position: 'absolute', top: -9, right: 12, display: 'inline-flex', alignItems: 'center', gap: 3,
          background: HM.suppDark, color: '#fff', borderRadius: 999, padding: '3px 9px',
          fontSize: 10, fontWeight: 800,
        }}>
          <Icon name="auto_awesome" size={11} />AI 입력
        </span>
      ) : null}
    </div>
  );
}
function MealChips({ selected, aiPick }) {
  return (
    <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
      {['아침', '점심', '저녁', '자기 전'].map(function (m, i) {
        const on = selected.includes(i);
        return (
          <span key={i} style={{
            position: 'relative', padding: '10px 16px', borderRadius: 999, fontSize: 13.5, fontWeight: 700,
            background: on ? HM.supp : HM.surface,
            color: on ? '#fff' : HM.muted,
            border: `1.5px solid ${on ? HM.supp : HM.line}`,
          }}>
            {m}
            {aiPick === i ? (
              <span style={{ position: 'absolute', top: -9, left: '50%', transform: 'translateX(-50%)', background: HM.suppDark, color: '#fff', borderRadius: 999, padding: '2px 7px', fontSize: 9.5, fontWeight: 800, whiteSpace: 'nowrap' }}>AI 추천</span>
            ) : null}
          </span>
        );
      })}
    </div>
  );
}
function StickySave({ enabled }) {
  return (
    <div style={{ padding: '12px 18px 10px', background: HM.bg, borderTop: `1px solid ${HM.line}` }}>
      <div style={{
        height: 52, borderRadius: 14, display: 'flex', alignItems: 'center', justifyContent: 'center',
        background: enabled ? HM.supp : HM.line, color: enabled ? '#fff' : HM.faint,
        fontSize: 15.5, fontWeight: 800,
      }}>저장하기</div>
    </div>
  );
}

// ════════════════════════════════════════════════════════════
// 초기 상태 — 사진 카드가 AI 가치를 설명
// ════════════════════════════════════════════════════════════
function HaruAddEmpty() {
  return (
    <Phone>
      <div style={{ flex: 1, padding: '6px 18px 0', display: 'flex', flexDirection: 'column', gap: 20, overflow: 'hidden' }}>
        <SubHeader title="영양제 추가" />
        {/* 사진 카드: 원형 버튼 → 가치 설명이 있는 카드 */}
        <div style={{
          background: HM.surface, borderRadius: 18, border: `1.5px dashed ${HM.supp}66`,
          padding: '22px 20px', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 5,
        }}>
          <div style={{ width: 72, height: 72, borderRadius: '50%', background: HM.suppTint, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Icon name="photo_camera" size={30} color={HM.suppDark} />
          </div>
          <div style={{ fontSize: 14.5, fontWeight: 800, marginTop: 8 }}>사진을 찍어보세요</div>
          <div style={{ fontSize: 12, color: HM.muted, textAlign: 'center', lineHeight: 1.55 }}>
            통 사진 한 장이면 AI가 이름·복용 시간·팁을<br />자동으로 채워줘요
          </div>
        </div>
        <div>
          <FieldLabel>영양제 이름</FieldLabel>
          <TextInput hint="예: 비타민C, 오메가3" />
        </div>
        <div>
          <FieldLabel>복용 시간</FieldLabel>
          <MealChips selected={[0]} />
          <div style={{ fontSize: 11.5, color: HM.faint, marginTop: 8 }}>여러 시간대를 선택할 수 있어요</div>
        </div>
        <div>
          <FieldLabel>복용 팁 <span style={{ fontWeight: 500, color: HM.faint }}>(선택)</span></FieldLabel>
          <TextInput hint="AI 분석 시 자동으로 채워져요" />
        </div>
      </div>
      <StickySave enabled={false} />
    </Phone>
  );
}

// ════════════════════════════════════════════════════════════
// AI 분석 완료 — 자동 분석 + 인라인 'AI 입력' 뱃지 (스낵바 대체)
// ════════════════════════════════════════════════════════════
function HaruAddAI() {
  return (
    <Phone>
      <div style={{ flex: 1, padding: '6px 18px 0', display: 'flex', flexDirection: 'column', gap: 20, overflow: 'hidden' }}>
        <SubHeader title="영양제 추가" />
        {/* 사진 등록됨 + 분석 완료 배너 */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 14, background: HM.surface, borderRadius: 18, padding: 14 }}>
          <div style={{ width: 64, height: 64, borderRadius: '50%', background: '#E8D9A0', display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'relative' }}>
            <Icon name="pill" size={28} fill={1} color="#9C7C2E" />
            <span style={{ position: 'absolute', right: -4, bottom: -4, width: 22, height: 22, borderRadius: 11, background: HM.surface, display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 1px 4px rgba(0,0,0,0.15)' }}>
              <Icon name="photo_camera" size={13} color={HM.muted} />
            </span>
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
              <Icon name="auto_awesome" size={15} color={HM.suppDark} />
              <span style={{ fontSize: 13.5, fontWeight: 800, color: HM.suppDark }}>AI 분석 완료</span>
            </div>
            <div style={{ fontSize: 11.5, color: HM.muted, marginTop: 3, lineHeight: 1.5 }}>
              사진을 바꾸면 다시 분석해요
            </div>
          </div>
          <span style={{ fontSize: 12, fontWeight: 700, color: HM.primaryDark }}>다시 분석</span>
        </div>
        <div>
          <FieldLabel>영양제 이름</FieldLabel>
          <TextInput value="비타민D 1000IU" aiTag={true} />
        </div>
        <div>
          <FieldLabel>복용 시간</FieldLabel>
          <MealChips selected={[0]} aiPick={0} />
          <div style={{ fontSize: 11.5, color: HM.faint, marginTop: 10 }}>여러 시간대를 선택할 수 있어요</div>
        </div>
        <div>
          <FieldLabel>복용 팁 <span style={{ fontWeight: 500, color: HM.faint }}>(선택)</span></FieldLabel>
          <TextInput value="지용성이라 식사 직후에 드시는 게 흡수에 좋아요" aiTag={true} />
        </div>
      </div>
      <StickySave enabled={true} />
    </Phone>
  );
}

Object.assign(window, { HaruAddEmpty, HaruAddAI });
