import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';
import '../providers/water_provider.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(waterGoalProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionHeader('물 섭취 설정'),
          const SizedBox(height: 10),
          _SettingsCard(
            child: ListTile(
              title: const Text('하루 목표량',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('현재 ${goal}ml'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showGoalPicker(context, ref, goal),
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader('알림 설정'),
          const SizedBox(height: 10),
          const _WaterNotiCard(),
          const SizedBox(height: 10),
          const _SupplementNotiCard(),
          const SizedBox(height: 24),
          _SectionHeader('앱 정보'),
          const SizedBox(height: 10),
          _SettingsCard(
            child: const ListTile(
              title: Text('버전',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              trailing: Text('1.0.0',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          ),
        ],
      ),
    );
  }

  void _showGoalPicker(BuildContext context, WidgetRef ref, int current) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const Text('하루 목표량 선택',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          ...[1500, 1800, 2000, 2500, 3000].map((ml) => ListTile(
                title: Text('$ml ml'),
                trailing: current == ml
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  ref.read(waterGoalProvider.notifier).setGoal(ml);
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: 16),
        ],
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
          if (noti.enabled)
            _NotiTimeRow(
              time: noti.timeOfDay,
              onTap: () => _pickTime(context, ref, noti),
            ),
        ],
      ),
    );
  }

  Future<void> _handleToggle(
      BuildContext context, WidgetRef ref, bool val, NotiSetting noti) async {
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

  Future<void> _pickTime(
      BuildContext context, WidgetRef ref, NotiSetting noti) async {
    final picked =
        await showTimePicker(context: context, initialTime: noti.timeOfDay);
    if (picked != null && context.mounted) {
      await ref.read(notificationProvider.notifier).updateWater(
            noti.copyWith(hour: picked.hour, minute: picked.minute),
          );
    }
  }
}

// ─── 영양제 알림 카드 ──────────────────────────────────────────

class _SupplementNotiCard extends ConsumerWidget {
  const _SupplementNotiCard();

  static const _mealTimes = ['morning', 'lunch', 'dinner', 'bedtime'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);
    final rows = <Widget>[];
    for (int i = 0; i < _mealTimes.length; i++) {
      if (i > 0) {
        rows.add(const Divider(height: 1, indent: 56, endIndent: 16));
      }
      final mealTime = _mealTimes[i];
      rows.add(_SupplementNotiRow(
        mealTime: mealTime,
        noti: state.supplement(mealTime),
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

  const _SupplementNotiRow({required this.mealTime, required this.noti});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _NotiToggleRow(
          icon: Icons.medication_rounded,
          iconColor: AppColors.supplement,
          title: _labels[mealTime]!,
          enabled: noti.enabled,
          onChanged: (val) => _handleToggle(context, ref, val),
        ),
        if (noti.enabled)
          _NotiTimeRow(
            time: noti.timeOfDay,
            onTap: () => _pickTime(context, ref),
          ),
      ],
    );
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
