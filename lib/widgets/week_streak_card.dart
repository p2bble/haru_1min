import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../providers/supplement_provider.dart';
import '../providers/water_provider.dart';
import '../screens/stats_screen.dart';
import '../theme/app_theme.dart';

/// 홈 하단 주간 스트릭 카드 — 월~일 7일 달성 현황. 탭하면 통계 화면으로.
class WeekStreakCard extends ConsumerWidget {
  const WeekStreakCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(waterGoalProvider);
    final todayWater = ref.watch(waterAmountProvider);
    final supplements = ref.watch(supplementListProvider);
    final takenIds = ref.watch(takenSupplementIdsProvider);

    return FutureBuilder<List<_DayStatus>>(
      future: _loadWeek(goal, todayWater, supplements.length, takenIds.length),
      builder: (context, snapshot) {
        final days = snapshot.data;
        final achieved =
            days?.where((d) => !d.isFuture && d.level == 2).length ?? 0;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StatsScreen()),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        '이번 주 기록',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        achieved > 0 ? '$achieved일 달성 중' : '시작이 반이에요',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var i = 0; i < 7; i++)
                        _DayDot(
                          label: _weekLabels[i],
                          status: days != null && i < days.length
                              ? days[i]
                              : const _DayStatus(0, isToday: false, isFuture: true),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ),
        );
      },
    );
  }

  Future<List<_DayStatus>> _loadWeek(
      int goal, int todayWater, int suppTotal, int todayTakenCount) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: now.weekday - 1));
    final fmt = DateFormat('yyyy-MM-dd');

    final db = DbHelper();
    final waterTotals = await db.getDailyWaterTotals(fmt.format(monday));
    final suppCounts = await db.getDailySupplementCounts(fmt.format(monday));

    return List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      final isToday = day == today;
      final isFuture = day.isAfter(today);
      final key = fmt.format(day);

      final water = isToday ? todayWater : (waterTotals[key] ?? 0);
      final taken = isToday ? todayTakenCount : (suppCounts[key] ?? 0);

      final waterMet = goal > 0 && water >= goal;
      final suppMet = suppTotal > 0 && taken >= suppTotal;
      // 영양제를 안 쓰는 유저는 물 목표만으로 달성 판정
      final level = suppTotal == 0
          ? (waterMet ? 2 : 0)
          : (waterMet ? 1 : 0) + (suppMet ? 1 : 0);

      return _DayStatus(level, isToday: isToday, isFuture: isFuture);
    });
  }

  static const _weekLabels = ['월', '화', '수', '목', '금', '토', '일'];
}

class _DayStatus {
  /// 2 = 물+영양제 모두 달성, 1 = 하나만, 0 = 미달성
  final int level;
  final bool isToday;
  final bool isFuture;

  const _DayStatus(this.level, {required this.isToday, required this.isFuture});
}

class _DayDot extends StatelessWidget {
  final String label;
  final _DayStatus status;

  const _DayDot({required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(width: 32, height: 32, child: _buildDot()),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: status.isToday ? FontWeight.w800 : FontWeight.w500,
            color: status.isToday ? AppColors.primaryDark : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDot() {
    // 오늘은 진행 중(점선 테두리), 단 모두 달성하면 채워진 점으로
    if (status.isToday && status.level < 2) {
      return CustomPaint(
        painter: _DashedCirclePainter(color: AppColors.primary),
        child: status.level == 1
            ? const Icon(Icons.check, size: 15, color: AppColors.primaryDark)
            : null,
      );
    }

    if (status.isFuture) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.notTaken.withValues(alpha: 0.6),
            width: 2,
          ),
        ),
      );
    }

    switch (status.level) {
      case 2:
        return const DecoratedBox(
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
          child: Icon(Icons.check, size: 15, color: Colors.white),
        );
      case 1:
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.15),
          ),
          child: const Icon(Icons.check, size: 15, color: AppColors.primaryDark),
        );
      default:
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.notTaken, width: 2),
          ),
        );
    }
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;

  const _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()
      ..addOval(Rect.fromLTWH(1, 1, size.width - 2, size.height - 2));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 4), paint);
        distance += 8;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter old) => old.color != color;
}
