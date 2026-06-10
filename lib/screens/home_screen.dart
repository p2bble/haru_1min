import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/supplement.dart';
import '../providers/supplement_provider.dart';
import '../providers/water_provider.dart';
import '../services/widget_service.dart';
import '../theme/app_theme.dart';
import '../widgets/supplement_card.dart';
import '../widgets/water_tracker_widget.dart';
import 'add_supplement_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

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
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const WaterTrackerWidget(),
              const SizedBox(height: 24),
              _SupplementSection(
                supplements: supplements,
                takenCount: takenCount,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddSupplementScreen()),
        ),
        backgroundColor: AppColors.supplement,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('영양제 추가', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _SupplementSection extends ConsumerWidget {
  final List<Supplement> supplements;
  final int takenCount;

  const _SupplementSection({required this.supplements, required this.takenCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            if (supplements.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.supplement.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$takenCount / ${supplements.length}',
                  style: const TextStyle(
                    color: AppColors.supplementDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (supplements.isEmpty)
          _EmptySupplementHint()
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.85,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: supplements.length,
            itemBuilder: (_, i) => SupplementCard(
              supplement: supplements[i],
              onLongPress: () => _showOptions(context, ref, supplements[i]),
            ),
          ),
        if (supplements.isNotEmpty && takenCount == supplements.length) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.taken.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: AppColors.taken, size: 18),
                SizedBox(width: 8),
                Text(
                  '오늘 영양제 모두 완료!',
                  style: TextStyle(color: AppColors.taken, fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref, Supplement supplement) {
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
            leading: const Icon(Icons.delete_rounded, color: Colors.red),
            title: const Text('삭제', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(context, ref, supplement);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Supplement supplement) {
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

class _EmptySupplementHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.notTaken, width: 1.5),
      ),
      child: const Column(
        children: [
          Icon(Icons.add_circle_outline, color: AppColors.notTaken, size: 40),
          SizedBox(height: 10),
          Text(
            '아래 버튼으로 영양제를 추가해보세요',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
