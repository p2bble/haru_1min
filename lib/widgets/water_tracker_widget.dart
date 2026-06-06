import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../providers/water_provider.dart';
import '../theme/app_theme.dart';

class WaterTrackerWidget extends ConsumerWidget {
  const WaterTrackerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(waterAmountProvider);
    final goal = ref.watch(waterGoalProvider);
    final cupSize = ref.watch(waterCupSizeProvider);
    final percent = (total / goal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                '오늘의 물',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              _CupSizeSelector(cupSize: cupSize, ref: ref),
            ],
          ),
          const SizedBox(height: 20),
          CircularPercentIndicator(
            radius: 70,
            lineWidth: 12,
            percent: percent,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$total',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                Text(
                  'ml / ${goal}ml',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            progressColor: AppColors.primary,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
            animateFromLastPercent: true,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _WaterButton(
                  label: '+${cupSize}ml',
                  icon: Icons.add,
                  color: AppColors.primary,
                  onTap: () => ref.read(waterAmountProvider.notifier).add(cupSize),
                ),
              ),
              const SizedBox(width: 10),
              _UndoButton(
                onTap: () => ref.read(waterAmountProvider.notifier).undoLast(),
              ),
            ],
          ),
          if (percent >= 1.0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.celebration, size: 16, color: AppColors.primaryDark),
                  SizedBox(width: 6),
                  Text(
                    '오늘 목표 달성!',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WaterButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _WaterButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UndoButton extends StatelessWidget {
  final VoidCallback onTap;

  const _UndoButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.textSecondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.undo,
          color: AppColors.textSecondary,
          size: 20,
        ),
      ),
    );
  }
}

class _CupSizeSelector extends StatelessWidget {
  final int cupSize;
  final WidgetRef ref;

  const _CupSizeSelector({required this.cupSize, required this.ref});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSelector(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${cupSize}ml',
          style: const TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _showSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const Text('한 잔 용량 선택', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          ...[150, 200, 250, 300, 350, 500].map((ml) => ListTile(
                title: Text('$ml ml'),
                trailing: cupSize == ml ? const Icon(Icons.check, color: AppColors.primary) : null,
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
