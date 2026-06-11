import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/supplement.dart';
import '../providers/notification_provider.dart';
import '../providers/supplement_provider.dart';
import '../providers/water_provider.dart';
import '../services/widget_service.dart';
import '../theme/app_theme.dart';
import '../widgets/supplement_card.dart';
import '../widgets/water_tracker_widget.dart';
import '../widgets/week_streak_card.dart';
import 'add_supplement_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

const _mealTimeOrder = ['morning', 'lunch', 'dinner', 'bedtime'];

const _mealTimeIcons = {
  'morning': Icons.light_mode,
  'lunch': Icons.wb_sunny,
  'dinner': Icons.wb_twilight,
  'bedtime': Icons.bedtime,
};

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncWidget());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(waterAmountProvider.notifier).loadToday();
      ref.read(takenSupplementIdsProvider.notifier).loadToday();
    }
  }

  Future<void> _syncWidget() async {
    final waterAmount = ref.read(waterAmountProvider);
    final waterGoal = ref.read(waterGoalProvider);
    final cupSize = ref.read(waterCupSizeProvider);
    final supplements = ref.read(supplementListProvider);
    final takenIds = ref.read(takenSupplementIdsProvider);

    await WidgetService.update(
      waterAmount: waterAmount,
      waterGoal: waterGoal,
      cupSize: cupSize,
      supplementTaken: supplements.where((s) => takenIds.contains(s.id)).length,
      supplementTotal: supplements.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final supplements = ref.watch(supplementListProvider);
    final takenIds = ref.watch(takenSupplementIdsProvider);
    final today = DateFormat('M월 d일 EEEE', 'ko').format(DateTime.now());
    final takenCount = supplements.where((s) => takenIds.contains(s.id)).length;

    // 상태 변화 감지 → 위젯 동기화
    ref.listen(waterAmountProvider, (prev, next) => _syncWidget());
    ref.listen(takenSupplementIdsProvider, (prev, next) => _syncWidget());
    ref.listen(supplementListProvider, (prev, next) => _syncWidget());

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('하루 1분', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text(today, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StatsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(waterAmountProvider.notifier).loadToday();
          ref.read(takenSupplementIdsProvider.notifier).loadToday();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const WaterTrackerWidget(),
              const SizedBox(height: 24),
              _SupplementSection(
                supplements: supplements,
                takenCount: takenCount,
              ),
              const SizedBox(height: 24),
              const WeekStreakCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupplementSection extends ConsumerStatefulWidget {
  final List<Supplement> supplements;
  final int takenCount;

  const _SupplementSection({required this.supplements, required this.takenCount});

  @override
  ConsumerState<_SupplementSection> createState() => _SupplementSectionState();
}

class _SupplementSectionState extends ConsumerState<_SupplementSection> {
  final Set<String> _expandedSlots = {};
  bool _showTip = false;

  @override
  void initState() {
    super.initState();
    _loadTipFlag();
  }

  Future<void> _loadTipFlag() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('tip_card_menu_shown') ?? false) && mounted) {
      setState(() => _showTip = true);
    }
  }

  Future<void> _dismissTip() async {
    if (!_showTip) return;
    setState(() => _showTip = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tip_card_menu_shown', true);
  }

  /// 알림 설정의 시간대별 시각을 재사용해 현재 시간대 판정.
  /// 인접 시간대의 중간 시각을 경계로 사용 (기본값 기준 ~10시 아침, 10~15시 점심,
  /// 15~20시 저녁, 20시~ 자기 전). 새벽 4시 이전은 자기 전으로 취급.
  String _currentMealTime(NotificationState noti) {
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    if (nowMin < 4 * 60) return 'bedtime';

    final times = [
      for (final slot in _mealTimeOrder)
        noti.supplement(slot).hour * 60 + noti.supplement(slot).minute,
    ];
    if (nowMin < (times[0] + times[1]) ~/ 2) return 'morning';
    if (nowMin < (times[1] + times[2]) ~/ 2) return 'lunch';
    if (nowMin < (times[2] + times[3]) ~/ 2) return 'dinner';
    return 'bedtime';
  }

  @override
  Widget build(BuildContext context) {
    final supplements = widget.supplements;
    final takenIds = ref.watch(takenSupplementIdsProvider);
    final noti = ref.watch(notificationProvider);
    final allDone = supplements.isNotEmpty && widget.takenCount == supplements.length;
    final current = _currentMealTime(noti);

    final groups = <String, List<Supplement>>{};
    for (final slot in _mealTimeOrder) {
      final items = supplements.where((s) => s.mealTime == slot).toList();
      if (items.isNotEmpty) groups[slot] = items;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.medication_rounded, color: AppColors.supplement, size: 20),
            const SizedBox(width: 8),
            const Text(
              '오늘의 영양제',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const Spacer(),
            if (supplements.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.supplement.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.takenCount} / ${supplements.length}',
                  style: const TextStyle(
                    color: AppColors.supplementDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppColors.supplement.withValues(alpha: 0.15),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddSupplementScreen()),
                  ),
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(Icons.add, size: 20, color: AppColors.supplementDark),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        if (supplements.isEmpty)
          const _EmptySupplementHint()
        else ...[
          if (_showTip) _MenuTip(onDismiss: _dismissTip),
          if (allDone) ...[
            _doneBanner('오늘 영양제 모두 완료!', big: true),
            const SizedBox(height: 10),
          ],
          for (final entry in groups.entries) ...[
            if (!allDone && entry.key == current)
              _isSlotDone(entry.value, takenIds)
                  ? _doneBanner('${mealTimeLabels[entry.key]} 영양제 모두 완료!')
                  : _NowGroup(
                      slot: entry.key,
                      items: entry.value,
                      takenIds: takenIds,
                      onMore: (s) => _showOptions(context, s),
                    )
            else
              _SlotRow(
                slot: entry.key,
                items: entry.value,
                takenIds: takenIds,
                expanded: _expandedSlots.contains(entry.key),
                onToggleExpand: () => setState(() {
                  _expandedSlots.contains(entry.key)
                      ? _expandedSlots.remove(entry.key)
                      : _expandedSlots.add(entry.key);
                }),
                onMore: (s) => _showOptions(context, s),
              ),
            if (entry.key != groups.keys.last) const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }

  bool _isSlotDone(List<Supplement> items, Set<int> takenIds) =>
      items.every((s) => takenIds.contains(s.id));

  Widget _doneBanner(String text, {bool big = false}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: big ? 13 : 11),
      decoration: BoxDecoration(
        color: AppColors.taken.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: AppColors.taken, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(color: AppColors.taken, fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context, Supplement supplement) {
    _dismissTip();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Text(supplement.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          if (supplement.memo != null && supplement.memo!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
              child: Text(
                '💡 ${supplement.memo}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.edit_rounded, color: AppColors.supplement),
            title: const Text('수정'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddSupplementScreen(existing: supplement),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_rounded, color: AppColors.primaryDark),
            title: const Text('알림 시간'),
            subtitle: Text(
              '${mealTimeLabels[supplement.mealTime]} ${ref.read(notificationProvider).supplement(supplement.mealTime).timeOfDay.format(context)}',
              style: const TextStyle(fontSize: 12),
            ),
            onTap: () {
              Navigator.pop(context);
              _pickNotiTime(supplement);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_rounded, color: Colors.red),
            title: const Text('삭제', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(context, supplement);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _pickNotiTime(Supplement supplement) async {
    final setting = ref.read(notificationProvider).supplement(supplement.mealTime);
    final picked = await showTimePicker(context: context, initialTime: setting.timeOfDay);
    if (picked == null || !mounted) return;
    await ref.read(notificationProvider.notifier).updateSupplement(
          supplement.mealTime,
          setting.copyWith(enabled: true, hour: picked.hour, minute: picked.minute),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${mealTimeLabels[supplement.mealTime]} 알림을 ${picked.format(context)}에 받아요'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Supplement supplement) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('영양제 삭제'),
        content: Text('${supplement.name}을(를) 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              ref.read(supplementListProvider.notifier).remove(supplement.id!);
              Navigator.pop(context);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// 현재 시간대 강조 그룹 — 틴트 배경 + "아침 · 지금" 라벨 + 카드 그리드
class _NowGroup extends StatelessWidget {
  final String slot;
  final List<Supplement> items;
  final Set<int> takenIds;
  final void Function(Supplement) onMore;

  const _NowGroup({
    required this.slot,
    required this.items,
    required this.takenIds,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = items.where((s) => !takenIds.contains(s.id)).length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.supplement.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: Row(
              children: [
                Icon(_mealTimeIcons[slot], size: 15, color: AppColors.supplementDark),
                const SizedBox(width: 6),
                Text(
                  '${mealTimeLabels[slot]} · 지금',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.supplementDark,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${items.length}개 중 $remaining개 남았어요',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.supplementDark.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          _SupplementGrid(items: items, onMore: onMore),
        ],
      ),
    );
  }
}

/// 다른 시간대 컴팩트 행 — 탭하면 그 자리에서 펼쳐 체크 가능
class _SlotRow extends StatelessWidget {
  final String slot;
  final List<Supplement> items;
  final Set<int> takenIds;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final void Function(Supplement) onMore;

  const _SlotRow({
    required this.slot,
    required this.items,
    required this.takenIds,
    required this.expanded,
    required this.onToggleExpand,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final done = items.every((s) => takenIds.contains(s.id));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onToggleExpand,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Row(
                  children: [
                    Icon(_mealTimeIcons[slot], size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Text(
                      mealTimeLabels[slot]!,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        items.map((s) => s.name).join(' · '),
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (done && !expanded)
                      const Icon(Icons.check_circle, size: 17, color: AppColors.taken)
                    else
                      Icon(
                        expanded ? Icons.expand_less : Icons.chevron_right,
                        size: 18,
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                  ],
                ),
              ),
            ),
            if (expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: _SupplementGrid(items: items, onMore: onMore),
              ),
          ],
        ),
      ),
    );
  }
}

class _SupplementGrid extends StatelessWidget {
  final List<Supplement> items;
  final void Function(Supplement) onMore;

  const _SupplementGrid({required this.items, required this.onMore});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => SupplementCard(
        supplement: items[i],
        onLongPress: () => onMore(items[i]),
        onMore: () => onMore(items[i]),
      ),
    );
  }
}

/// 첫 영양제 등록 직후 1회 노출되는 ⋯ 메뉴 안내 툴팁
class _MenuTip extends StatelessWidget {
  final VoidCallback onDismiss;

  const _MenuTip({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '⋯ 또는 길게 눌러 수정해요',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
            Transform.translate(
              offset: const Offset(28, -4),
              child: Transform.rotate(
                angle: math.pi / 4,
                child: Container(width: 8, height: 8, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 첫 실행 빈 상태 — 점선 카드 + "사진으로 등록" CTA (FAB 제거 후의 등록 동선)
class _EmptySupplementHint extends StatelessWidget {
  const _EmptySupplementHint();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRRectPainter(color: AppColors.notTaken, radius: 18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.supplement.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.medication_rounded, color: AppColors.supplement, size: 30),
            ),
            const SizedBox(height: 14),
            const Text(
              '드시는 영양제가 있나요?',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              '사진으로 등록하면 매일 체크만 하면 돼요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.6),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.supplement,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 46),
                padding: const EdgeInsets.symmetric(horizontal: 22),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              icon: const Icon(Icons.photo_camera, size: 17),
              label: const Text('사진으로 등록'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddSupplementScreen(autoPhoto: true)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedRRectPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
        Radius.circular(radius),
      ));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 6), paint);
        distance += 11;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}
