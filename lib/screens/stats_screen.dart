import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../providers/supplement_provider.dart';
import '../providers/water_provider.dart';
import '../theme/app_theme.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  final _db = DbHelper();

  /// 오래된 날 → 오늘 순서의 최근 7일
  late final List<DateTime> _week = List.generate(
    7,
    (i) => DateTime.now().subtract(Duration(days: 6 - i)),
  );

  Map<String, int> _waterTotals = {};
  Map<String, int> _suppCounts = {};
  bool _loading = true;

  static final _keyFmt = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final weekFromKey = _keyFmt.format(_week.first);
    // 스트릭 계산용으로 1년 치 영양제 기록을 가져온다
    final streakFromKey = _keyFmt.format(
      DateTime.now().subtract(const Duration(days: 365)),
    );
    final water = await _db.getDailyWaterTotals(weekFromKey);
    final supp = await _db.getDailySupplementCounts(streakFromKey);
    if (mounted) {
      setState(() {
        _waterTotals = water;
        _suppCounts = supp;
        _loading = false;
      });
    }
  }

  int _waterOf(DateTime day) => _waterTotals[_keyFmt.format(day)] ?? 0;

  /// 그날 활성 영양제를 전부 복용했는지 (현재 활성 개수 기준)
  bool _suppDone(DateTime day, int activeCount) {
    if (activeCount == 0) return false;
    return (_suppCounts[_keyFmt.format(day)] ?? 0) >= activeCount;
  }

  /// 연속 복용 일수 — 오늘이 미완료면 어제부터 거슬러 센다
  int _streak(int activeCount) {
    if (activeCount == 0) return 0;
    var day = DateTime.now();
    if (!_suppDone(day, activeCount)) {
      day = day.subtract(const Duration(days: 1));
    }
    var count = 0;
    while (_suppDone(day, activeCount)) {
      count++;
      day = day.subtract(const Duration(days: 1));
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final goal = ref.watch(waterGoalProvider);
    final activeCount = ref.watch(supplementListProvider).length;

    return Scaffold(
      appBar: AppBar(title: const Text('통계')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _WaterStatsCard(
                  week: _week,
                  amountOf: _waterOf,
                  goal: goal,
                ),
                const SizedBox(height: 16),
                _SupplementStatsCard(
                  week: _week,
                  doneOf: (d) => _suppDone(d, activeCount),
                  streak: _streak(activeCount),
                  hasSupplements: activeCount > 0,
                ),
              ],
            ),
    );
  }
}

// ─── 물 통계 카드 ────────────────────────────────────────────

class _WaterStatsCard extends StatelessWidget {
  final List<DateTime> week;
  final int Function(DateTime) amountOf;
  final int goal;

  const _WaterStatsCard({
    required this.week,
    required this.amountOf,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    final amounts = week.map(amountOf).toList();
    final weekTotal = amounts.fold(0, (a, b) => a + b);
    final achievedDays = amounts.where((a) => a >= goal).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.water_drop, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text('주간 물 섭취',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 20),
          _WeekBarChart(week: week, amounts: amounts, goal: goal),
          const SizedBox(height: 20),
          Row(
            children: [
              _StatItem(
                label: '주 평균',
                value: '${(weekTotal / 7 / 1000).toStringAsFixed(1)}L',
              ),
              _StatItem(label: '목표 달성', value: '$achievedDays일 / 7일'),
              _StatItem(
                label: '오늘',
                value: '${(amounts.last / 1000).toStringAsFixed(1)}L',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekBarChart extends StatelessWidget {
  final List<DateTime> week;
  final List<int> amounts;
  final int goal;

  const _WeekBarChart({
    required this.week,
    required this.amounts,
    required this.goal,
  });

  static const _chartHeight = 120.0;
  static const _dayNames = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    final maxAmount = amounts.fold(0, (a, b) => a > b ? a : b);
    // 목표선이 항상 차트 안에 들어오도록 최대값을 잡는다
    final maxValue = (maxAmount > goal ? maxAmount : goal) * 1.15;
    final goalFraction = goal / maxValue;

    return Column(
      children: [
        SizedBox(
          height: _chartHeight,
          child: Stack(
            children: [
              // 목표선
              Positioned(
                left: 0,
                right: 0,
                bottom: _chartHeight * goalFraction,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: AppColors.primaryDark.withValues(alpha: 0.35),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '목표 ${(goal / 1000).toStringAsFixed(1)}L',
                      style: const TextStyle(
                          fontSize: 9, color: AppColors.primaryDark),
                    ),
                  ],
                ),
              ),
              // 막대들
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(week.length, (i) {
                  final fraction =
                      maxValue == 0 ? 0.0 : amounts[i] / maxValue;
                  final achieved = amounts[i] >= goal;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: (_chartHeight - 14) * fraction,
                            decoration: BoxDecoration(
                              color: achieved
                                  ? AppColors.primary
                                  : AppColors.primary.withValues(alpha: 0.35),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(week.length, (i) {
            final isToday = i == week.length - 1;
            return Expanded(
              child: Text(
                _dayNames[week[i].weekday - 1],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                  color: isToday
                      ? AppColors.primaryDark
                      : AppColors.textSecondary,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ─── 영양제 통계 카드 ──────────────────────────────────────────

class _SupplementStatsCard extends StatelessWidget {
  final List<DateTime> week;
  final bool Function(DateTime) doneOf;
  final int streak;
  final bool hasSupplements;

  const _SupplementStatsCard({
    required this.week,
    required this.doneOf,
    required this.streak,
    required this.hasSupplements,
  });

  static const _dayNames = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.medication_rounded,
                  color: AppColors.supplement, size: 20),
              SizedBox(width: 8),
              Text('영양제 복용',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          if (!hasSupplements)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('영양제를 등록하면 복용 통계가 표시돼요',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            )
          else ...[
            // 스트릭
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.supplement.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    streak > 0 ? '🔥 $streak일 연속 복용 중!' : '오늘부터 시작해보세요 💪',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.supplementDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 주간 체크 그리드
            Row(
              children: List.generate(week.length, (i) {
                final done = doneOf(week[i]);
                final isToday = i == week.length - 1;
                return Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: done ? AppColors.taken : AppColors.notTaken,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          done ? Icons.check : Icons.remove,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _dayNames[week[i].weekday - 1],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isToday ? FontWeight.w700 : FontWeight.w400,
                          color: isToday
                              ? AppColors.supplementDark
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── 공통 ────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
