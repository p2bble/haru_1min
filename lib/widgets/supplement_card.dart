import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/supplement.dart';
import '../providers/supplement_provider.dart';
import '../theme/app_theme.dart';

class SupplementCard extends ConsumerWidget {
  final Supplement supplement;
  final VoidCallback? onLongPress;

  /// 카드 우상단 ⋯ 버튼 — 롱프레스의 보이는 대안 (수정/삭제 진입점)
  final VoidCallback? onMore;

  const SupplementCard({
    super.key,
    required this.supplement,
    this.onLongPress,
    this.onMore,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final takenIds = ref.watch(takenSupplementIdsProvider);
    final isTaken = takenIds.contains(supplement.id);
    final c = context.c;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isTaken ? c.taken.withValues(alpha: 0.1) : c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTaken ? c.taken : c.notTaken,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            HapticFeedback.lightImpact();
            ref.read(takenSupplementIdsProvider.notifier).toggle(supplement.id!);
          },
          onLongPress: onLongPress,
          child: Stack(
            children: [
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        _SupplementImage(imagePath: supplement.imagePath, isTaken: isTaken),
                        if (isTaken)
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: c.taken.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.check_rounded, color: c.taken, size: 32),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        supplement.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isTaken ? c.taken : c.textPrimary,
                        ),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isTaken
                            ? c.taken.withValues(alpha: 0.15)
                            : c.supplement.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        mealTimeLabels[supplement.mealTime] ?? supplement.mealTime,
                        style: TextStyle(
                          fontSize: 10,
                          color: isTaken ? c.taken : c.supplementDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (onMore != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onMore,
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: Icon(
                        Icons.more_horiz,
                        size: 18,
                        color: context.c.textSecondary.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupplementImage extends StatelessWidget {
  final String? imagePath;
  final bool isTaken;

  const _SupplementImage({required this.imagePath, required this.isTaken});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (imagePath != null && File(imagePath!).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Image.file(
          File(imagePath!),
          width: 64,
          height: 64,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: c.supplement.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.medication_rounded,
        color: isTaken ? c.taken : c.supplement,
        size: 32,
      ),
    );
  }
}
