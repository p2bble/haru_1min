// @ds-adherence-ignore -- 하루 1분 목업 (외부 앱 컨설팅용)
// 통계 · 설정 화면 개선

// 서브 화면 헤더 (뒤로가기 + 타이틀)
function SubHeader({ title }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '8px 2px 0' }}>
      <Icon name="arrow_back" size={22} color={HM.ink} />
      <span style={{ fontSize: 19, fontWeight: 800 }}>{title}</span>
    </div>
  );
}

// ════════════════════════════════════════════════════════════
// 통계 — 주 네비게이션 · 오늘 막대 강조 · 스트릭 행 (이모지 제거)
// ════════════════════════════════════════════════════════════
function HaruStats() {
  const bars = [0.7, 1.0, 0.45, 0.9, 1.0, 0.55, 0.75]; // 목표 대비
  const days = ['금', '토', '일', '월', '화', '수', '목'];
  const vals = ['1.4', '2.1', '0.9', '1.8', '2.0', '1.1', '1.5'];
  const chartH = 110, goalFrac = 0.78;
  return (
    <Phone>
      <div style={{ flex: 1, padding: '6px 18px 14px', display: 'flex', flexDirection: 'column', gap: 14, overflow: 'hidden' }}>
        <SubHeader title="통계" />

        {/* 주 네비게이션 */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 14 }}>
          <Icon name="chevron_left" size={20} color={HM.muted} />
          <span style={{ fontSize: 13.5, fontWeight: 700 }}>6월 5일 ~ 6월 11일</span>
          <Pill label="이번 주" size="sm" bg={HM.primaryTint} color={HM.primaryDark} />
          <Icon name="chevron_right" size={20} color={HM.faint} />
        </div>

        {/* 물 카드 */}
        <HCard>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <Icon name="water_drop" size={18} fill={1} color={HM.primary} />
            <span style={{ fontSize: 15.5, fontWeight: 700 }}>주간 물 섭취</span>
          </div>
          {/* 바 차트: 오늘 강조 + 달성일 체크 */}
          <div style={{ position: 'relative', height: chartH, marginTop: 18 }}>
            <div style={{ position: 'absolute', left: 0, right: 0, bottom: chartH * goalFrac, display: 'flex', alignItems: 'center', gap: 5 }}>
              <div style={{ flex: 1, borderTop: `1.5px dashed ${HM.primaryDark}55` }}></div>
              <span style={{ fontSize: 10.5, fontWeight: 600, color: HM.primaryDark }}>목표 2.0L</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'flex-end', height: '100%', gap: 10 }}>
              {bars.map(function (b, i) {
                const today = i === 6, hit = b >= 1;
                return (
                  <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'flex-end', gap: 4, height: '100%' }}>
                    {today ? <span style={{ fontSize: 10.5, fontWeight: 800, color: HM.primaryDark }}>{vals[i]}L</span> : null}
                    <div style={{
                      width: '100%', height: chartH * goalFrac * b * 0.92, borderRadius: '5px 5px 0 0',
                      background: hit ? HM.primary : `${HM.primary}55`,
                      outline: today ? `2px solid ${HM.primaryDark}` : 'none', outlineOffset: -1,
                    }}></div>
                  </div>
                );
              })}
            </div>
          </div>
          <div style={{ display: 'flex', gap: 10, marginTop: 6 }}>
          {days.map(function (d, i) {
            return <span key={i} style={{ flex: 1, textAlign: 'center', fontSize: 11, fontWeight: i === 6 ? 800 : 500, color: i === 6 ? HM.primaryDark : HM.muted }}>{d}</span>;
          })}
          </div>
          <div style={{ display: 'flex', marginTop: 16, borderTop: `1px solid ${HM.line}`, paddingTop: 14 }}>
            {[['주 평균', '1.5L'], ['목표 달성', '3일 / 7일'], ['오늘', '1.5L']].map(function (s, i) {
              return (
                <div key={i} style={{ flex: 1, textAlign: 'center' }}>
                  <div style={{ fontSize: 11, color: HM.muted }}>{s[0]}</div>
                  <div style={{ fontSize: 15, fontWeight: 800, marginTop: 3 }}>{s[1]}</div>
                </div>
              );
            })}
          </div>
        </HCard>

        {/* 영양제 카드 */}
        <HCard>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <Icon name="pill" size={18} fill={1} color={HM.supp} />
            <span style={{ fontSize: 15.5, fontWeight: 700 }}>영양제 복용</span>
          </div>
          {/* 스트릭: 이모지 → 아이콘, 최장 기록 함께 */}
          <div style={{ display: 'flex', gap: 10, marginTop: 14 }}>
            <div style={{ flex: 1.4, background: HM.suppTint, borderRadius: 12, padding: '12px 14px', display: 'flex', alignItems: 'center', gap: 10 }}>
              <Icon name="local_fire_department" size={22} fill={1} color="#F57C00" />
              <div>
                <div style={{ fontSize: 16, fontWeight: 800, color: HM.suppDark }}>12일 연속</div>
                <div style={{ fontSize: 11, color: HM.suppDark, opacity: 0.75 }}>복용 중</div>
              </div>
            </div>
            <div style={{ flex: 1, background: HM.bg, borderRadius: 12, padding: '12px 14px' }}>
              <div style={{ fontSize: 11, color: HM.muted }}>최장 기록</div>
              <div style={{ fontSize: 16, fontWeight: 800, marginTop: 2 }}>21일</div>
            </div>
          </div>
          <div style={{ display: 'flex', gap: 10, marginTop: 14 }}>
            {days.map(function (d, i) {
              const done = [true, true, false, true, true, true, true][i];
              const today = i === 6;
              return (
                <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
                  <div style={{
                    width: 30, height: 30, borderRadius: '50%',
                    background: done ? HM.taken : 'transparent',
                    border: done ? 'none' : `2px solid ${HM.line}`,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                  }}>
                    {done ? <Icon name="check" size={15} color="#fff" weight={700} /> : null}
                  </div>
                  <span style={{ fontSize: 11, fontWeight: today ? 800 : 500, color: today ? HM.suppDark : HM.muted }}>{d}</span>
                </div>
              );
            })}
          </div>
        </HCard>
      </div>
    </Phone>
  );
}

// ════════════════════════════════════════════════════════════
// 설정 — 한 잔 용량 행 추가 · 영양제 알림은 등록된 시간대만
// ════════════════════════════════════════════════════════════
function SetRow({ icon, iconColor, title, sub, right, dim }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '13px 16px', opacity: dim ? 0.5 : 1 }}>
      {icon ? <Icon name={icon} size={20} color={iconColor || HM.muted} /> : null}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 14, fontWeight: 700 }}>{title}</div>
        {sub ? <div style={{ fontSize: 11.5, color: HM.muted, marginTop: 1 }}>{sub}</div> : null}
      </div>
      {right}
    </div>
  );
}
function Toggle({ on, color = HM.primary }) {
  return (
    <div style={{ width: 44, height: 26, borderRadius: 13, background: on ? color : HM.line, position: 'relative', flexShrink: 0 }}>
      <div style={{ position: 'absolute', top: 3, left: on ? 21 : 3, width: 20, height: 20, borderRadius: 10, background: '#fff', boxShadow: '0 1px 3px rgba(0,0,0,0.2)' }}></div>
    </div>
  );
}
function SetCard({ children }) {
  return <div style={{ background: HM.surface, borderRadius: 16, boxShadow: '0 2px 12px rgba(79,195,247,0.07)' }}>{children}</div>;
}
function SetDivider() { return <div style={{ height: 1, background: HM.line, marginLeft: 48 }}></div>; }
function SetSection({ label }) {
  return <div style={{ fontSize: 12.5, fontWeight: 800, color: HM.muted, letterSpacing: 0.3, margin: '6px 2px -4px' }}>{label}</div>;
}

function HaruSettings() {
  const timeChip = (t) => (
    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, background: HM.bg, borderRadius: 8, padding: '5px 9px', fontSize: 12.5, fontWeight: 700, color: HM.primaryDark }}>
      <Icon name="schedule" size={13} />{t}
    </span>
  );
  return (
    <Phone>
      <div style={{ flex: 1, padding: '6px 18px 14px', display: 'flex', flexDirection: 'column', gap: 12, overflow: 'hidden' }}>
        <SubHeader title="설정" />

        <SetSection label="물 섭취" />
        <SetCard>
          <SetRow icon="flag" iconColor={HM.primary} title="하루 목표량" sub="현재 2000ml"
            right={<Icon name="chevron_right" size={18} color={HM.faint} />} />
          <SetDivider />
          <SetRow icon="local_drink" iconColor={HM.primary} title="한 잔 용량" sub="현재 250ml — 홈에서도 바꿀 수 있어요"
            right={<Icon name="chevron_right" size={18} color={HM.faint} />} />
        </SetCard>

        <SetSection label="알림" />
        <SetCard>
          <SetRow icon="water_drop" iconColor={HM.primary} title="물 마시기 알림" sub="오전 9시 ~ 오후 9시 · 2시간마다"
            right={<Toggle on={true} />} />
        </SetCard>
        <SetCard>
          <SetRow icon="pill" iconColor={HM.supp} title="아침 영양제" right={<span style={{ display: 'inline-flex', alignItems: 'center', gap: 10 }}>{timeChip('오전 8:00')}<Toggle on={true} color={HM.supp} /></span>} />
          <SetDivider />
          <SetRow icon="pill" iconColor={HM.supp} title="저녁 영양제" right={<span style={{ display: 'inline-flex', alignItems: 'center', gap: 10 }}>{timeChip('오후 7:30')}<Toggle on={true} color={HM.supp} /></span>} />
          <SetDivider />
          <SetRow icon="pill" iconColor={HM.supp} title="자기 전 영양제" right={<Toggle on={false} />} />
          <SetDivider />
          <SetRow icon="info" title="점심" sub="이 시간대에 등록된 영양제가 없어요" dim={true} />
        </SetCard>

        <SetSection label="데이터" />
        <SetCard>
          <SetRow icon="backup" iconColor={HM.primary} title="백업 만들기" sub="기록과 사진을 파일 하나로 내보내요"
            right={<Icon name="chevron_right" size={18} color={HM.faint} />} />
          <SetDivider />
          <SetRow icon="settings_backup_restore" iconColor={HM.primary} title="백업에서 복원" sub="백업 파일로 기록을 되돌려요"
            right={<Icon name="chevron_right" size={18} color={HM.faint} />} />
        </SetCard>

        <SetSection label="앱 정보" />
        <SetCard>
          <SetRow icon="info" title="버전" right={<span style={{ fontSize: 13, color: HM.muted }}>1.0.0</span>} />
        </SetCard>
      </div>
    </Phone>
  );
}

// ════════════════════════════════════════════════════════════
// 목표량 시트 — 프리셋 5택 → 프리셋 + 스테퍼
// ════════════════════════════════════════════════════════════
function HPatGoalSheet() {
  return (
    <div style={{ width: '100%', boxSizing: 'border-box', minHeight: '100%', padding: 20, background: HM.bg, fontFamily: "'Pretendard Variable', Pretendard, sans-serif", color: HM.ink }}>
      <div style={{ fontSize: 12, fontWeight: 700, color: HM.muted, marginBottom: 14, letterSpacing: 0.3 }}>하루 목표량 시트 — 커스텀 값 지원</div>
      <div style={{ background: HM.surface, borderRadius: '20px 20px 16px 16px', padding: '14px 18px 18px', boxShadow: '0 -6px 24px rgba(26,26,46,0.08)' }}>
        <div style={{ width: 40, height: 4, borderRadius: 2, background: HM.line, margin: '0 auto 14px' }}></div>
        <div style={{ fontSize: 15.5, fontWeight: 800, textAlign: 'center' }}>하루 목표량</div>
        {/* 스테퍼 */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 22, margin: '16px 0 6px' }}>
          <div style={{ width: 44, height: 44, borderRadius: 22, background: HM.primaryTint, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Icon name="remove" size={20} color={HM.primaryDark} weight={600} />
          </div>
          <div style={{ textAlign: 'center', width: 120 }}>
            <span style={{ fontSize: 32, fontWeight: 800, color: HM.primaryDark }}>2000</span>
            <span style={{ fontSize: 14, color: HM.muted, marginLeft: 3 }}>ml</span>
          </div>
          <div style={{ width: 44, height: 44, borderRadius: 22, background: HM.primaryTint, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Icon name="add" size={20} color={HM.primaryDark} weight={600} />
          </div>
        </div>
        <div style={{ fontSize: 11.5, color: HM.faint, textAlign: 'center' }}>100ml 단위로 조절</div>
        {/* 프리셋 */}
        <div style={{ display: 'flex', gap: 7, justifyContent: 'center', marginTop: 14 }}>
          {['1.5L', '1.8L', '2.0L', '2.5L', '3.0L'].map(function (p, i) {
            const on = i === 2;
            return <span key={i} style={{ padding: '7px 12px', borderRadius: 999, fontSize: 12.5, fontWeight: 700, background: on ? HM.primary : HM.bg, color: on ? '#fff' : HM.muted }}>{p}</span>;
          })}
        </div>
        <div style={{ height: 48, borderRadius: 14, background: HM.primary, color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 15, fontWeight: 800, marginTop: 16 }}>저장</div>
      </div>
      <div style={{ marginTop: 12, fontSize: 12, color: HM.muted, lineHeight: 1.6 }}>
        프리셋 5택 고정 → <b style={{ color: HM.ink }}>스테퍼(100ml 단위) + 프리셋 칩</b>.<br />
        2200ml 같은 맞춤 목표가 가능해져요. 한 잔 용량 시트도 같은 패턴.
      </div>
    </div>
  );
}

Object.assign(window, { SubHeader, HaruStats, HaruSettings, HPatGoalSheet, SetRow, Toggle, SetCard });
