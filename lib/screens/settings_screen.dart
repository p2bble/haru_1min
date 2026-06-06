import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/water_provider.dart';
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
          const Text('물 섭취 설정', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          _SettingsCard(
            child: ListTile(
              title: const Text('하루 목표량', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('현재 ${goal}ml'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showGoalPicker(context, ref, goal),
            ),
          ),
          const SizedBox(height: 24),
          const Text('앱 정보', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          _SettingsCard(
            child: const ListTile(
              title: Text('버전', style: TextStyle(fontWeight: FontWeight.w600)),
              trailing: Text('1.0.0', style: TextStyle(color: AppColors.textSecondary)),
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
          const Text('하루 목표량 선택', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          ...[1500, 1800, 2000, 2500, 3000].map((ml) => ListTile(
                title: Text('$ml ml'),
                trailing: current == ml ? const Icon(Icons.check, color: AppColors.primary) : null,
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
