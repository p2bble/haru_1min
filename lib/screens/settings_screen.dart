import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/notification_provider.dart';
import '../services/battery_service.dart';
import '../providers/supplement_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/water_provider.dart';
import '../services/backup_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(waterGoalProvider);
    final cupSize = ref.watch(waterCupSizeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final c = context.c;

    final themeModeLabel = switch (themeMode) {
      ThemeMode.light => '라이트',
      ThemeMode.dark => '다크',
      _ => '시스템 기본',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionHeader('물 섭취 설정'),
          const SizedBox(height: 10),
          _SettingsCard(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.flag_outlined, color: c.primary, size: 22),
                  title: const Text('하루 목표량',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('현재 ${goal}ml'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showGoalPicker(context, ref, goal),
                ),
                const Divider(height: 1, indent: 56, endIndent: 16),
                ListTile(
                  leading:
                      Icon(Icons.local_drink_outlined, color: c.primary, size: 22),
                  title: const Text('한 잔 용량',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('현재 ${cupSize}ml — 홈에서도 바꿀 수 있어요'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showCupSizePicker(context, ref, cupSize),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader('알림 설정'),
          const SizedBox(height: 10),
          const _WaterNotiCard(),
          const SizedBox(height: 10),
          const _SupplementNotiCard(),
          const _BatteryHintCard(),
          const SizedBox(height: 24),
          _SectionHeader('화면'),
          const SizedBox(height: 10),
          _SettingsCard(
            child: ListTile(
              leading:
                  Icon(Icons.brightness_6_outlined, color: c.primary, size: 22),
              title: const Text('화면 테마',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(themeModeLabel),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showThemePicker(context, ref, themeMode),
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader('데이터 관리'),
          const SizedBox(height: 10),
          const _BackupCard(),
          const SizedBox(height: 24),
          _SectionHeader('앱 정보'),
          const SizedBox(height: 10),
          _SettingsCard(
            child: ListTile(
              title: const Text('버전',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              trailing: FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (_, snap) => Text(
                  snap.data?.version ?? '',
                  style: TextStyle(color: context.c.textSecondary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 테마 선택 다이얼로그 ──────────────────────────────────────
  void _showThemePicker(
      BuildContext context, WidgetRef ref, ThemeMode current) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('화면 테마'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ThemeOption(
              label: '시스템 기본',
              mode: ThemeMode.system,
              current: current,
              onTap: () {
                ref.read(themeModeProvider.notifier).setMode(ThemeMode.system);
                Navigator.pop(ctx);
              },
            ),
            _ThemeOption(
              label: '라이트',
              mode: ThemeMode.light,
              current: current,
              onTap: () {
                ref.read(themeModeProvider.notifier).setMode(ThemeMode.light);
                Navigator.pop(ctx);
              },
            ),
            _ThemeOption(
              label: '다크',
              mode: ThemeMode.dark,
              current: current,
              onTap: () {
                ref.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 목표량 시트 — 스테퍼(100ml 단위) + 프리셋 칩, 맞춤 목표 지원
  void _showGoalPicker(BuildContext context, WidgetRef ref, int current) {
    var value = current;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('하루 목표량',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15.5)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StepperButton(
                    icon: Icons.remove,
                    onTap: value > 500
                        ? () => setSheetState(() => value -= 100)
                        : null,
                  ),
                  SizedBox(
                    width: 130,
                    child: Text.rich(
                      TextSpan(
                        text: '$value',
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: ctx.c.primaryDark),
                        children: [
                          TextSpan(
                            text: ' ml',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: ctx.c.textSecondary),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  _StepperButton(
                    icon: Icons.add,
                    onTap: value < 5000
                        ? () => setSheetState(() => value += 100)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('100ml 단위로 조절',
                  style: TextStyle(
                      fontSize: 11.5, color: ctx.c.textSecondary)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 7,
                alignment: WrapAlignment.center,
                children: [1500, 1800, 2000, 2500, 3000].map((ml) {
                  final on = value == ml;
                  return ChoiceChip(
                    label: Text('${(ml / 1000).toStringAsFixed(1)}L'),
                    selected: on,
                    onSelected: (_) => setSheetState(() => value = ml),
                    selectedColor: ctx.c.primary,
                    labelStyle: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: on ? Colors.white : ctx.c.textSecondary,
                    ),
                    backgroundColor: ctx.c.background,
                    side: BorderSide(
                      color: on ? ctx.c.primary : ctx.c.notTaken,
                    ),
                    visualDensity: VisualDensity.compact,
                    showCheckmark: false,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  ref.read(waterGoalProvider.notifier).setGoal(value);
                  Navigator.pop(sheetContext);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: ctx.c.primary,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800),
                ),
                child: const Text('저장'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCupSizePicker(BuildContext context, WidgetRef ref, int current) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const Text('한 잔 용량 선택',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          ...[150, 200, 250, 300, 350, 500].map((ml) => ListTile(
                title: Text('$ml ml'),
                trailing: current == ml
                    ? Icon(Icons.check, color: ctx.c.primary)
                    : null,
                onTap: () {
                  ref.read(waterCupSizeProvider.notifier).setCupSize(ml);
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── 테마 선택 옵션 행 ────────────────────────────────────────

class _ThemeOption extends StatelessWidget {
  final String label;
  final ThemeMode mode;
  final ThemeMode current;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.mode,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = current == mode;
    return ListTile(
      title: Text(label),
      trailing: selected
          ? Icon(Icons.check_circle, color: context.c.primary)
          : null,
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}

// ─── 스테퍼 버튼 ─────────────────────────────────────────────

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: onTap != null
          ? c.primary.withValues(alpha: 0.12)
          : c.notTaken.withValues(alpha: 0.4),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            size: 20,
            color: onTap != null
                ? c.primaryDark
                : c.textSecondary.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 14,
        color: context.c.textSecondary,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.c.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

// ─── 백업/복원 카드 ──────────────────────────────────────────

class _BackupCard extends ConsumerWidget {
  const _BackupCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.backup_outlined, color: c.primary, size: 22),
            title: const Text('백업 만들기',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: const Text('기록과 사진을 파일 하나로 내보내요',
                style: TextStyle(fontSize: 12)),
            onTap: () async {
              final err = await BackupService.exportBackup();
              if (err != null && context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(err)));
              }
            },
          ),
          const Divider(height: 1, indent: 56, endIndent: 16),
          ListTile(
            leading: Icon(Icons.restore, color: c.primary, size: 22),
            title: const Text('백업에서 복원',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: const Text('백업 파일로 기록을 되돌려요',
                style: TextStyle(fontSize: 12)),
            onTap: () => _confirmRestore(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRestore(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('백업에서 복원'),
        content: const Text(
            '현재 앱의 모든 기록(물·영양제·사진)이 백업 파일의 내용으로 교체됩니다.\n'
            '설정값(목표량·알림)은 그대로 유지돼요.\n계속할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('복원')),
        ],
      ),
    );
    if (ok != true) return;

    final err = await BackupService.importBackup();
    if (err == 'cancelled') return;
    if (err == null) {
      // 복원된 DB로 상태 재로드
      ref.invalidate(supplementListProvider);
      ref.invalidate(takenSupplementIdsProvider);
      ref.invalidate(waterAmountProvider);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err ?? '복원이 완료됐어요!')));
    }
  }
}

// ─── 배터리 최적화 안내 카드 ──────────────────────────────────

/// 배터리 최적화가 켜져 있으면(예외 미등록) 알림이 지연될 수 있다는 안내.
/// 예외로 등록돼 있으면 아무것도 그리지 않는다.
class _BatteryHintCard extends StatefulWidget {
  const _BatteryHintCard();

  @override
  State<_BatteryHintCard> createState() => _BatteryHintCardState();
}

class _BatteryHintCardState extends State<_BatteryHintCard>
    with WidgetsBindingObserver {
  bool _ignoring = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 설정에서 돌아왔을 때 상태 재확인 → 허용됐으면 카드 제거
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final ignoring = await BatteryService.isIgnoringOptimizations();
    if (mounted) setState(() => _ignoring = ignoring);
  }

  @override
  Widget build(BuildContext context) {
    if (_ignoring) return const SizedBox.shrink();
    final c = context.c;
    const color = Color(0xFFF57C00);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: BatteryService.requestIgnoreOptimizations,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.battery_alert_rounded,
                    size: 20, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '알림이 늦게 도착할 수 있어요',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: color),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '절전 기능이 알림을 미뤄요. 눌러서 배터리 사용을 허용해주세요.',
                        style: TextStyle(
                            fontSize: 11.5,
                            color: c.textSecondary,
                            height: 1.4),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    size: 18, color: c.textSecondary.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 물 알림 카드 ────────────────────────────────────────────

class _WaterNotiCard extends ConsumerWidget {
  const _WaterNotiCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noti = ref.watch(notificationProvider).water;
    final c = context.c;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _NotiToggleRow(
            icon: Icons.water_drop,
            iconColor: c.primary,
            title: '물 마시기 알림',
            enabled: noti.enabled,
            onChanged: (val) => _handleToggle(context, ref, val, noti),
          ),
          if (noti.enabled) ...[
            // 모드 선택: 하루 한 번 / 주기적으로
            Padding(
              padding: const EdgeInsets.fromLTRB(56, 0, 16, 10),
              child: Row(
                children: [
                  _modeChip(context, ref, noti,
                      label: '하루 한 번', repeat: false),
                  const SizedBox(width: 8),
                  _modeChip(context, ref, noti,
                      label: '주기적으로', repeat: true),
                ],
              ),
            ),
            if (!noti.repeat)
              _NotiTimeRow(
                time: noti.timeOfDay,
                onTap: () => _pickOnceTime(context, ref, noti),
              )
            else
              _RepeatSettingRows(noti: noti),
          ],
        ],
      ),
    );
  }

  Widget _modeChip(BuildContext context, WidgetRef ref, WaterNotiSetting noti,
      {required String label, required bool repeat}) {
    final selected = noti.repeat == repeat;
    final c = context.c;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => ref
          .read(notificationProvider.notifier)
          .updateWater(noti.copyWith(repeat: repeat)),
      selectedColor: c.primary,
      labelStyle: TextStyle(
        color: selected ? Colors.white : c.textSecondary,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: c.background,
      side: BorderSide(
        color: selected ? c.primary : c.notTaken,
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  Future<void> _handleToggle(BuildContext context, WidgetRef ref, bool val,
      WaterNotiSetting noti) async {
    if (val) {
      final granted = await NotificationService.requestPermission();
      if (!granted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('알림 권한을 허용해주세요')),
          );
        }
        return;
      }
      // 제조사 절전이 알람을 지우지 않도록 정확 알람 권한도 요청
      await NotificationService.ensureExactAlarmPermission();
    }
    await ref
        .read(notificationProvider.notifier)
        .updateWater(noti.copyWith(enabled: val));
  }

  Future<void> _pickOnceTime(
      BuildContext context, WidgetRef ref, WaterNotiSetting noti) async {
    final picked =
        await showTimePicker(context: context, initialTime: noti.timeOfDay);
    if (picked != null && context.mounted) {
      await ref.read(notificationProvider.notifier).updateWater(
            noti.copyWith(hour: picked.hour, minute: picked.minute),
          );
    }
  }
}

/// 반복 모드: 시작·종료 시각 + 간격 선택
class _RepeatSettingRows extends ConsumerWidget {
  final WaterNotiSetting noti;

  const _RepeatSettingRows({required this.noti});

  String _hourLabel(int hour) {
    final period = hour < 12 ? '오전' : '오후';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$period $h시';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(56, 0, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _hourButton(
                context,
                label: _hourLabel(noti.startHour),
                onTap: () => _pickHour(context, ref, isStart: true),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text('~',
                    style: TextStyle(color: c.textSecondary)),
              ),
              _hourButton(
                context,
                label: _hourLabel(noti.endHour),
                onTap: () => _pickHour(context, ref, isStart: false),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [1, 2, 3].map((h) {
              final selected = noti.intervalHours == h;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label:
                      Text('$h시간마다', style: const TextStyle(fontSize: 12)),
                  selected: selected,
                  onSelected: (_) => ref
                      .read(notificationProvider.notifier)
                      .updateWater(noti.copyWith(intervalHours: h)),
                  selectedColor: c.primary,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : c.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: c.background,
                  side: BorderSide(
                    color: selected ? c.primary : c.notTaken,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _hourButton(BuildContext context,
      {required String label, required VoidCallback onTap}) {
    final c = context.c;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: c.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: c.primaryDark,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Future<void> _pickHour(BuildContext context, WidgetRef ref,
      {required bool isStart}) async {
    final initial =
        TimeOfDay(hour: isStart ? noti.startHour : noti.endHour, minute: 0);
    final picked =
        await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !context.mounted) return;

    final start = isStart ? picked.hour : noti.startHour;
    final end = isStart ? noti.endHour : picked.hour;
    if (end <= start) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('종료 시각은 시작 시각보다 늦어야 해요')),
      );
      return;
    }
    await ref
        .read(notificationProvider.notifier)
        .updateWater(noti.copyWith(startHour: start, endHour: end));
  }
}

// ─── 영양제 알림 카드 ──────────────────────────────────────────

class _SupplementNotiCard extends ConsumerWidget {
  const _SupplementNotiCard();

  static const _mealTimes = ['morning', 'lunch', 'dinner', 'bedtime'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);
    // 영양제가 등록된 시간대만 알림 설정 가능 — 없는 시간대는 흐림 처리
    final usedMealTimes =
        ref.watch(supplementListProvider).map((s) => s.mealTime).toSet();
    final rows = <Widget>[];
    for (int i = 0; i < _mealTimes.length; i++) {
      if (i > 0) {
        rows.add(const Divider(height: 1, indent: 56, endIndent: 16));
      }
      final mealTime = _mealTimes[i];
      rows.add(_SupplementNotiRow(
        mealTime: mealTime,
        noti: state.supplement(mealTime),
        hasSupplements: usedMealTimes.contains(mealTime),
      ));
    }
    return Container(
      decoration: BoxDecoration(
        color: context.c.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: rows),
    );
  }
}

class _SupplementNotiRow extends ConsumerWidget {
  static const _labels = {
    'morning': '아침 영양제',
    'lunch': '점심 영양제',
    'dinner': '저녁 영양제',
    'bedtime': '자기 전 영양제',
  };

  final String mealTime;
  final NotiSetting noti;
  final bool hasSupplements;

  const _SupplementNotiRow({
    required this.mealTime,
    required this.noti,
    required this.hasSupplements,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    if (!hasSupplements) {
      return Opacity(
        opacity: 0.5,
        child: ListTile(
          leading: Icon(Icons.medication_rounded, color: c.supplement, size: 22),
          title: Text(_labels[mealTime]!,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          subtitle: const Text('이 시간대에 등록된 영양제가 없어요',
              style: TextStyle(fontSize: 11.5)),
        ),
      );
    }
    return ListTile(
      leading: Icon(Icons.medication_rounded, color: c.supplement, size: 22),
      title: Text(_labels[mealTime]!,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 설정된 시각 칩 상시 노출 — 펼치지 않아도 한눈에
          if (noti.enabled) ...[
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _pickTime(context, ref),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: c.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule, size: 13, color: c.primaryDark),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(noti.timeOfDay),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: c.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Switch(
            value: noti.enabled,
            onChanged: (val) => _handleToggle(context, ref, val),
            activeThumbColor: c.supplement,
            activeTrackColor: c.supplement.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final period = time.hour < 12 ? '오전' : '오후';
    final h =
        time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    return '$period $h:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _handleToggle(
      BuildContext context, WidgetRef ref, bool val) async {
    if (val) {
      final granted = await NotificationService.requestPermission();
      if (!granted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('알림 권한을 허용해주세요')),
          );
        }
        return;
      }
      // 제조사 절전이 알람을 지우지 않도록 정확 알람 권한도 요청
      await NotificationService.ensureExactAlarmPermission();
    }
    await ref
        .read(notificationProvider.notifier)
        .updateSupplement(mealTime, noti.copyWith(enabled: val));
  }

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final picked =
        await showTimePicker(context: context, initialTime: noti.timeOfDay);
    if (picked != null && context.mounted) {
      await ref.read(notificationProvider.notifier).updateSupplement(
            mealTime,
            noti.copyWith(hour: picked.hour, minute: picked.minute),
          );
    }
  }
}

// ─── 공통 위젯 ────────────────────────────────────────────────

class _NotiToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _NotiToggleRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      trailing: Switch(
        value: enabled,
        onChanged: onChanged,
        activeThumbColor: c.primary,
        activeTrackColor: c.primary.withValues(alpha: 0.4),
      ),
    );
  }
}

class _NotiTimeRow extends StatelessWidget {
  final TimeOfDay time;
  final VoidCallback onTap;

  const _NotiTimeRow({required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final period = time.hour < 12 ? '오전' : '오후';
    final h =
        time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final timeStr = '$period $h:${time.minute.toString().padLeft(2, '0')}';
    final c = context.c;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(56, 0, 16, 14),
        child: Row(
          children: [
            Icon(Icons.access_time, size: 16, color: c.textSecondary),
            const SizedBox(width: 6),
            Text(
              timeStr,
              style: TextStyle(
                color: c.primaryDark,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.edit, size: 13, color: c.textSecondary),
          ],
        ),
      ),
    );
  }
}
