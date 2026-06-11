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

  /// 0 = 이번 주(오늘로 끝나는 7일), 1 = 지난주, ...
  int _weeksAgo = 0;

  Map<String, int> _waterTotals = {};
  Map<String, int> _suppCounts = {};
  bool _loading = true;

  static final _keyFmt = DateFormat('yyyy-MM-dd');
  static final _labelFmt = DateFormat('M월 d일');

  /// 오래된 날 → 마지막 날 순서의 선택된 주 7일
  List<DateTime> get _week {
    final end = DateTime.now().subtract(Duration(days: 7 * _weeksAgo));
    return List.generate(7, (i) => end.subtract(Duration(days: 6 - i)));
  }

  @override
  void initState() {
    super.initState();
    _load(initial: true);
  }

  Future<void> _load({bool initial = false}) async {
    final weekFromKey = _keyFmt.format(_week.first);
    final water = await _db.getDailyWaterTotals(weekFromKey);
    Map<String, int>? supp;
    if (initial) {
      // 스트릭/최장 기록 계산용으로 1년 치 영양제 기록을 가져온다
      supp = await _db.getDailySupplementCounts(
        _keyFmt.format(DateTime.now().subtract(const Duration(days: 365))),
      );
    }
    if (mounted) {
      setState(() {
        _waterTotals = water;
        if (supp != null) _suppCounts = supp;
        _loading = false;
      });
    }
  }

  void _moveWeek(int delta) {
    final next = _weeksAgo + delta;
    if (next < 0 || next > 52) return;
    setState(() => _weeksAgo = next);
    _load();
  }

  int _waterOf(DateTime day) => _waterTotals[_keyFmt.format(day)] ?? 0;

  bool _isToday(DateTime day) =>
      _keyFmt.format(day) == _keyFmt.format(DateTime.now());

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

  /// 최근 1년 중 가장 길었던 연속 복용 구간
  int _longestStreak(int activeCount) {
    if (activeCount == 0) return 0;
    var best = 0;
    var current = 0;
    var day = DateTime.now().subtract(const Duration(days: 365));
    final today = DateTime.now();
    while (!day.isAfter(today)) {
      if (_suppDone(day, activeCount)) {
        current++;
        if (current > best) best = current;
      } else {
        current = 0;
      }
      day = day.add(const Duration(days: 1));
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final goal = ref.watch(waterGoalProvider);
    final activeCount = ref.watch(supplementListProvider).length;
    final week = _week;

    return Scaffold(
      appBar: AppBar(title: const Text('통계')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _WeekNavigator(
                  week: week,
                  isCurrentWeek: _weeksAgo == 0,
                  labelFmt: _labelFmt,
                  onPrev: () => _moveWeek(1),
                  onNext: _weeksAgo > 0 ? () => _moveWeek(-1) : null,
                ),
                const SizedBox(height: 14),
                _WaterStatsCard(
                  week: week,
                  amountOf: _waterOf,
                  isTodayOf: _isToday,
                  isCurrentWeek: _weeksAgo == 0,
                  goal: goal,
                ),
                const SizedBox(height: 16),
                _SupplementStatsCard(
                  week: week,
                  doneOf: (d) => _suppDone(d, activeCount),
                  isTodayOf: _isToday,
                  streak: _streak(activeCount),
                  longestStreak: _longestStreak(activeCount),
                  hasSupplements: activeCount > 0,
                ),
              ],
            ),
    );
  }
}

// ─── 주 네비게이션 ────────────────────────────────────────────

class _WeekNavigator extends StatelessWidget {
  final List<DateTime> week;
  final bool isCurrentWeek;
  final DateFormat labelFmt;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  const _WeekNavigator({
    required this.week,
    required this.isCurrentWeek,
    required this.labelFmt,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left, size: 22, color: AppColors.textSecondary),
          visualDensity: VisualDensity.compact,
        ),
        Text(
          '${labelFmt.format(week.first)} ~ ${labelFmt.format(week.last)}',
          style: const TextStyle(
              fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        if (isCurrentWeek) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '이번 주',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
            ),
          ),
        ],
        IconButton(
          onPressed: onNext,
          icon: Icon(
            Icons.chevron_right,
            size: 22,
            color: onNext != null
                ? AppColors.textSecondary
                : AppColors.notTaken,
          ),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

// ─── 물 통계 카드 ────────────────────────────────────────────

class _WaterStatsCard extends StatelessWidget {
  final List<DateTime> week;
  final int Function(DateTime) amountOf;
  final bool Function(DateTime) isTodayOf;
  final bool isCurrentWeek;
  final int goal;

  const _WaterStatsCard({
    required this.week,
    required this.amountOf,
    required this.isTodayOf,
    required this.isCurrentWeek,
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
          _WeekBarChart(
            week: week,
            amounts: amounts,
            goal: goal,
            isTodayOf: isTodayOf,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _StatItem(
                label: '주 평균',
                value: '${(weekTotal / 7 / 1000).toStringAsFixed(1)}L',
              ),
              _StatItem(label: '목표 달성', value: '$achievedDays일 / 7일'),
              _StatItem(
                label: isCurrentWeek ? '오늘' : '주 합계',
                value: isCurrentWeek
                    ? '${(amounts.last / 1000).toStringAsFixed(1)}L'
                    : '${(weekTotal / 1000).toStringAsFixed(1)}L',
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
  final bool Function(DateTime) isTodayOf;

  const _WeekBarChart({
    required this.week,
    required this.amounts,
    required this.goal,
    required this.isTodayOf,
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
              // 목표선 (점선)
              Positioned(
                left: 0,
                right: 0,
                bottom: _chartHeight * goalFraction,
                child: Row(
                  children: [
                    Expanded(
                      child: CustomPaint(
                        size: const Size(double.infinity, 1.5),
                        painter: _DashedLinePainter(
                          color: AppColors.primaryDark.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '목표 ${(goal / 1000).toStringAsFixed(1)}L',
                      style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark),
                    ),
                  ],
                ),
              ),
              // 막대들 — 오늘은 외곽선 + 값 라벨로 강조
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(week.length, (i) {
                  final fraction =
                      maxValue == 0 ? 0.0 : amounts[i] / maxValue;
                  final achieved = amounts[i] >= goal;
                  final isToday = isTodayOf(week[i]);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isToday && amounts[i] > 0) ...[
                            Text(
                              '${(amounts[i] / 1000).toStringAsFixed(1)}L',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 3),
                          ],
                          Container(
                            height: (_chartHeight - 18) * fraction,
                            decoration: BoxDecoration(
                              color: achieved
                                  ? AppColors.primary
                                  : AppColors.primary.withValues(alpha: 0.35),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                              border: isToday
                                  ? Border.all(
                                      color: AppColors.primaryDark, width: 2)
                                  : null,
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
            final isToday = isTodayOf(week[i]);
            return Expanded(
              child: Text(
                _dayNames[week[i].weekday - 1],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w400,
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

class _DashedLinePainter extends CustomPainter {
  final Color color;

  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    var x = 0.0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + 5, y), paint);
      x += 9;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) => old.color != color;
}

// ─── 영양제 통계 카드 ──────────────────────────────────────────

class _SupplementStatsCard extends StatelessWidget {
  final List<DateTime> week;
  final bool Function(DateTime) doneOf;
  final bool Function(DateTime) isTodayOf;
  final int streak;
  final int longestStreak;
  final bool hasSupplements;

  const _SupplementStatsCard({
    required this.week,
    required this.doneOf,
    required this.isTodayOf,
    required this.streak,
    required this.longestStreak,
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
            // 스트릭 + 최장 기록
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.supplement.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department,
                            size: 22, color: Color(0xFFF57C00)),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$streak일 연속',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.supplementDark,
                              ),
                            ),
                            Text(
                              streak > 0 ? '복용 중' : '오늘 시작해보세요',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.supplementDark
                                    .withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('최장 기록',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(
                          '$longestStreak일',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 주간 체크 그리드 — 미달성은 외곽선만 (시각 노이즈 감소)
            Row(
              children: List.generate(week.length, (i) {
                final done = doneOf(week[i]);
                final isToday = isTodayOf(week[i]);
                return Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: done ? AppColors.taken : Colors.transparent,
                          shape: BoxShape.circle,
                          border: done
                              ? null
                              : Border.all(color: AppColors.notTaken, width: 2),
                        ),
                        child: done
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 16)
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _dayNames[week[i].weekday - 1],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isToday ? FontWeight.w800 : FontWeight.w400,
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
