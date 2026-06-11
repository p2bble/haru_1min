import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/notification_provider.dart';
import '../providers/supplement_provider.dart';
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
                  leading: const Icon(Icons.flag_outlined,
                      color: AppColors.primary, size: 22),
                  title: const Text('하루 목표량',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('현재 ${goal}ml'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showGoalPicker(context, ref, goal),
                ),
                const Divider(height: 1, indent: 56, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.local_drink_outlined,
                      color: AppColors.primary, size: 22),
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
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          ),
        ],
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
        builder: (_, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('하루 목표량',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
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
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark),
                        children: const [
                          TextSpan(
                            text: ' ml',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textSecondary),
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
              const Text('100ml 단위로 조절',
                  style: TextStyle(
                      fontSize: 11.5, color: AppColors.textSecondary)),
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
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: on ? Colors.white : AppColors.textSecondary,
                    ),
                    backgroundColor: AppColors.background,
                    side: BorderSide(
                      color: on ? AppColors.primary : AppColors.notTaken,
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
                  backgroundColor: AppColors.primary,
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
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const Text('한 잔 용량 선택',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          ...[150, 200, 250, 300, 350, 500].map((ml) => ListTile(
                title: Text('$ml ml'),
                trailing: current == ml
                    ? const Icon(Icons.check, color: AppColors.primary)
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

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap != null
          ? AppColors.primary.withValues(alpha: 0.12)
          : AppColors.notTaken.withValues(alpha: 0.4),
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
                ? AppColors.primaryDark
                : AppColors.textSecondary.withValues(alpha: 0.4),
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
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 14,
        color: AppColors.textSecondary,
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
        color: AppColors.surface,
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.backup_outlined,
                color: AppColors.primary, size: 22),
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
            leading:
                const Icon(Icons.restore, color: AppColors.primary, size: 22),
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

// ─── 물 알림 카드 ────────────────────────────────────────────

class _WaterNotiCard extends ConsumerWidget {
  const _WaterNotiCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noti = ref.watch(notificationProvider).water;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _NotiToggleRow(
            icon: Icons.water_drop,
            iconColor: AppColors.primary,
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
                  _modeChip(context, ref, noti, label: '하루 한 번', repeat: false),
                  const SizedBox(width: 8),
                  _modeChip(context, ref, noti, label: '주기적으로', repeat: true),
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
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => ref
          .read(notificationProvider.notifier)
          .updateWater(noti.copyWith(repeat: repeat)),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: AppColors.background,
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.notTaken,
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('~',
                    style: TextStyle(color: AppColors.textSecondary)),
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
                  label: Text('$h시간마다', style: const TextStyle(fontSize: 12)),
                  selected: selected,
                  onSelected: (_) => ref
                      .read(notificationProvider.notifier)
                      .updateWater(noti.copyWith(intervalHours: h)),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: AppColors.background,
                  side: BorderSide(
                    color: selected ? AppColors.primary : AppColors.notTaken,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.primaryDark,
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
    final picked = await showTimePicker(context: context, initialTime: initial);
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
        color: AppColors.surface,
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
    if (!hasSupplements) {
      return Opacity(
        opacity: 0.5,
        child: ListTile(
          leading: const Icon(Icons.medication_rounded,
              color: AppColors.supplement, size: 22),
          title: Text(_labels[mealTime]!,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          subtitle: const Text('이 시간대에 등록된 영양제가 없어요',
              style: TextStyle(fontSize: 11.5)),
        ),
      );
    }
    return ListTile(
      leading: const Icon(Icons.medication_rounded,
          color: AppColors.supplement, size: 22),
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
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule,
                        size: 13, color: AppColors.primaryDark),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(noti.timeOfDay),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
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
            activeThumbColor: AppColors.supplement,
            activeTrackColor: AppColors.supplement.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final period = time.hour < 12 ? '오전' : '오후';
    final h = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
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
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      trailing: Switch(
        value: enabled,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
        activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
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
    final h = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final timeStr = '$period $h:${time.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(56, 0, 16, 14),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              timeStr,
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.edit, size: 13, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
