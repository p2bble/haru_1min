// @ds-adherence-ignore -- 하루 1분 목업 (외부 앱 컨설팅용, RE:BEAT DS 미적용)
// 공용 파츠: 컬러 토큰(app_theme.dart 기준), 아이콘, 폰 프레임 등

const HM = {
  primary: '#4FC3F7', primaryDark: '#0288D1', primaryTint: '#E3F4FD',
  supp: '#81C784', suppDark: '#388E3C', suppTint: '#EDF7EE',
  taken: '#4CAF50',
  bg: '#F5F9FF', surface: '#FFFFFF',
  ink: '#1A1A2E', muted: '#6B7280', faint: '#A8AFBE', line: '#E5E9F0',
};

function Icon({ name, size = 20, color = 'currentColor', fill = 0, weight = 400, style }) {
  return (
    <span
      className="msr"
      style={{
        fontSize: size, color, lineHeight: 1,
        fontVariationSettings: `'FILL' ${fill}, 'wght' ${weight}, 'GRAD' 0, 'opsz' 24`,
        ...style,
      }}
    >{name}</span>
  );
}

function Phone({ children, bg = HM.bg, width = 412, height = 892 }) {
  return (
    <div style={{
      width, height, borderRadius: 18, overflow: 'hidden',
      background: bg, border: '8px solid rgba(116,119,117,0.5)',
      display: 'flex', flexDirection: 'column', boxSizing: 'border-box',
      fontFamily: "'Pretendard Variable', Pretendard, sans-serif",
      color: HM.ink,
    }}>
      <AndroidStatusBar />
      <div style={{ flex: 1, overflow: 'hidden', display: 'flex', flexDirection: 'column' }}>
        {children}
      </div>
      <AndroidNavBar />
    </div>
  );
}

function HCard({ children, pad = 18, style }) {
  return (
    <div style={{
      background: HM.surface, borderRadius: 20, padding: pad,
      boxShadow: '0 4px 18px rgba(79,195,247,0.10)', ...style,
    }}>{children}</div>
  );
}

function SecH({ icon, iconColor, title, right }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
      <Icon name={icon} size={19} fill={1} color={iconColor} />
      <span style={{ fontSize: 16, fontWeight: 700 }}>{title}</span>
      <div style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: 8 }}>{right}</div>
    </div>
  );
}

// 알약 칩
function Pill({ label, bg, color, size = 'md', icon, style }) {
  const pad = size === 'md' ? '6px 12px' : '4px 10px';
  const fs = size === 'md' ? 12.5 : 11;
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 4,
      background: bg, color, borderRadius: 999, padding: pad,
      fontSize: fs, fontWeight: 700, ...style,
    }}>
      {label}{icon ? <Icon name={icon} size={fs + 2} /> : null}
    </span>
  );
}

// 원형 프로그레스 (물)
function WaterRing({ size = 150, stroke = 13, percent = 0.75, value = '1500', goal = '2000ml' }) {
  const r = (size - stroke) / 2, c = 2 * Math.PI * r;
  return (
    <div style={{ position: 'relative', width: size, height: size }}>
      <svg width={size} height={size} style={{ transform: 'rotate(-90deg)' }}>
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke={HM.primaryTint} strokeWidth={stroke}></circle>
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke={HM.primary} strokeWidth={stroke}
          strokeLinecap="round" strokeDasharray={`${c * percent} ${c}`}></circle>
      </svg>
      <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
        <span style={{ fontSize: 30, fontWeight: 800, color: HM.primaryDark }}>{value}</span>
        <span style={{ fontSize: 11.5, color: HM.muted }}>ml / {goal}</span>
      </div>
    </div>
  );
}

// 영양제 카드 (개선판: ⋯ 버튼 포함)
function SuppCard({ name, time, taken, color = HM.supp, showMore = true, style }) {
  return (
    <div style={{
      position: 'relative', borderRadius: 16, padding: '14px 8px 12px',
      background: taken ? 'rgba(76,175,80,0.08)' : HM.surface,
      border: `2px solid ${taken ? HM.taken : HM.line}`,
      display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 7, ...style,
    }}>
      {showMore ? (
        <span style={{ position: 'absolute', top: 6, right: 6, width: 24, height: 24, borderRadius: 12, display: 'flex', alignItems: 'center', justifyContent: 'center', color: HM.faint }}>
          <Icon name="more_horiz" size={17} />
        </span>
      ) : null}
      <div style={{ position: 'relative', width: 56, height: 56 }}>
        <div style={{
          width: 56, height: 56, borderRadius: '50%',
          background: taken ? 'rgba(76,175,80,0.18)' : `${color}26`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <Icon name="pill" size={26} color={taken ? HM.taken : HM.suppDark} fill={1} />
        </div>
        {taken ? (
          <div style={{ position: 'absolute', right: -3, bottom: -3, width: 22, height: 22, borderRadius: 11, background: HM.taken, border: '2px solid #fff', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Icon name="check" size={13} color="#fff" weight={700} />
          </div>
        ) : null}
      </div>
      <span style={{ fontSize: 12.5, fontWeight: 700, color: taken ? HM.taken : HM.ink, textAlign: 'center' }}>{name}</span>
      {time ? <Pill label={time} size="sm" bg={taken ? 'rgba(76,175,80,0.12)' : `${HM.supp}26`} color={taken ? HM.taken : HM.suppDark} /> : null}
    </div>
  );
}

// 주간 스트릭 (7일 점)
function WeekStreak({ days = [2, 2, 1, 2, 0, 2, -1], compact = false }) {
  // 2=물+영양제 모두, 1=하나만, 0=둘다 미달성, -1=오늘(진행중)
  const labels = ['월', '화', '수', '목', '금', '토', '일'];
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
      {days.map(function (d, i) {
        const today = d === -1;
        const bg = d === 2 ? HM.primary : d === 1 ? HM.primaryTint : 'transparent';
        return (
          <div key={i} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 5 }}>
            <div style={{
              width: compact ? 26 : 32, height: compact ? 26 : 32, borderRadius: '50%',
              background: today ? HM.surface : bg,
              border: today ? `2px dashed ${HM.primary}` : d === 0 ? `2px solid ${HM.line}` : '2px solid transparent',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              {d === 2 ? <Icon name="check" size={15} color="#fff" weight={700} /> : null}
              {d === 1 ? <Icon name="check" size={15} color={HM.primaryDark} weight={700} /> : null}
            </div>
            <span style={{ fontSize: 10.5, fontWeight: today ? 800 : 500, color: today ? HM.primaryDark : HM.muted }}>{labels[i]}</span>
          </div>
        );
      })}
    </div>
  );
}

Object.assign(window, { HM, Icon, Phone, HCard, SecH, Pill, WaterRing, SuppCard, WeekStreak });
