import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/supplement.dart';
import '../providers/supplement_provider.dart';
import '../services/image_store.dart';
import '../services/supplement_ai_service.dart';
import '../theme/app_theme.dart';

class AddSupplementScreen extends ConsumerStatefulWidget {
  final Supplement? existing;

  /// 빈 상태 "사진으로 등록" CTA에서 진입 시 사진 선택부터 시작
  final bool autoPhoto;

  const AddSupplementScreen({super.key, this.existing, this.autoPhoto = false});

  @override
  ConsumerState<AddSupplementScreen> createState() => _AddSupplementScreenState();
}

class _AddSupplementScreenState extends ConsumerState<AddSupplementScreen> {
  final _nameController = TextEditingController();
  final _memoController = TextEditingController();
  String _selectedMealTime = 'morning';
  String? _imagePath;
  List<NutrientAmount> _nutrients = const []; // AI 추출 성분 (중복 분석용)
  bool _isAnalyzing = false;
  bool _analyzed = false;

  // AI가 채운 필드 추적 — 유저가 값을 바꾸면 뱃지 해제
  bool _aiName = false;
  bool _aiTip = false;
  String? _aiNameValue;
  String? _aiTipValue;
  String? _aiMealTime;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameController.text = widget.existing!.name;
      _memoController.text = widget.existing!.memo ?? '';
      _selectedMealTime = widget.existing!.mealTime;
      _imagePath = widget.existing!.imagePath;
      _nutrients = widget.existing!.nutrients;
    }
    // 저장 버튼 활성화 + AI 뱃지 해제 갱신
    _nameController.addListener(() {
      if (_aiName && _nameController.text != _aiNameValue) _aiName = false;
      setState(() {});
    });
    _memoController.addListener(() {
      if (_aiTip && _memoController.text != _aiTipValue) {
        setState(() => _aiTip = false);
      }
    });
    if (widget.autoPhoto) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickImage());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _analyzeImage() async {
    if (_imagePath == null || _isAnalyzing) return;
    setState(() => _isAnalyzing = true);
    final result = await SupplementAiService.analyze(File(_imagePath!));
    if (!mounted) return;

    if (result == null) {
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('분석에 실패했어요. 네트워크를 확인하고 다시 시도해주세요.')),
      );
      return;
    }
    setState(() {
      _isAnalyzing = false;
      _analyzed = true;
      if (result.name != null && result.name!.isNotEmpty) {
        _aiNameValue = result.name;
        _nameController.text = result.name!;
        _aiName = true;
      }
      _selectedMealTime = result.mealTime;
      _aiMealTime = result.mealTime;
      _nutrients = result.nutrients;
      if (result.tip != null && result.tip!.isNotEmpty) {
        _aiTipValue = result.tip;
        _memoController.text = result.tip!;
        _aiTip = true;
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final file = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 80,
    );
    if (file != null) {
      final saved = await ImageStore.persist(file);
      setState(() {
        _imagePath = saved;
        _analyzed = false;
      });
      // 사진 선택 직후 자동 AI 분석 — 별도 버튼 단계 없음
      await _analyzeImage();
    }
  }

  Future<ImageSource?> _showImageSourceDialog() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const Text('사진 선택',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ListTile(
            leading: Icon(Icons.camera_alt_rounded, color: ctx.c.primary),
            title: const Text('카메라로 찍기'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: Icon(Icons.photo_library_rounded, color: ctx.c.primary),
            title: const Text('갤러리에서 선택'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final memo = _memoController.text.trim();
    if (widget.existing != null) {
      await ref.read(supplementListProvider.notifier).update(
            widget.existing!.copyWith(
              name: name,
              imagePath: _imagePath,
              mealTime: _selectedMealTime,
              memo: memo.isEmpty ? null : memo,
              nutrients: _nutrients,
            ),
          );
      if (_imagePath != widget.existing!.imagePath) {
        await ImageStore.deleteIfExists(widget.existing!.imagePath);
      }
    } else {
      await ref.read(supplementListProvider.notifier).add(
            Supplement(
              name: name,
              imagePath: _imagePath,
              mealTime: _selectedMealTime,
              memo: memo.isEmpty ? null : memo,
              nutrients: _nutrients,
              createdAt: DateTime.now(),
            ),
          );
    }

    if (mounted) Navigator.pop(context);
  }

  InputDecoration _fieldDecoration({required String hint, required bool aiFilled}) {
    final c = context.c;
    final aiBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c.supplement, width: 1.5),
    );
    final plainBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    );
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: c.surface,
      border: plainBorder,
      enabledBorder: aiFilled ? aiBorder : plainBorder,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _nameController.text.trim().isNotEmpty;
    final c = context.c;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing != null ? '영양제 수정' : '영양제 추가'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_imagePath == null)
              _PhotoValueCard(onTap: _pickImage)
            else
              _PhotoStatusCard(
                imagePath: _imagePath!,
                isAnalyzing: _isAnalyzing,
                analyzed: _analyzed,
                onChangePhoto: _pickImage,
                onReanalyze: _analyzeImage,
              ),
            const SizedBox(height: 28),
            const Text('영양제 이름',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 12),
            _AiTaggedField(
              showBadge: _aiName,
              child: TextField(
                controller: _nameController,
                enabled: !_isAnalyzing,
                decoration: _fieldDecoration(
                  hint: '예: 비타민C, 오메가3',
                  aiFilled: _aiName,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('복용 시간',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 14,
              children: mealTimeLabels.entries.map((e) {
                final selected = _selectedMealTime == e.key;
                final chip = ChoiceChip(
                  label: Text(e.value),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedMealTime = e.key),
                  selectedColor: c.supplement,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : c.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: c.surface,
                  side: BorderSide(
                    color: selected ? c.supplement : c.notTaken,
                  ),
                );
                if (_aiMealTime != e.key) return chip;
                // AI 추천 시간대 마커
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    chip,
                    Positioned(
                      top: -8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: c.supplementDark,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'AI 추천',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text('복용 팁 (선택)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 12),
            _AiTaggedField(
              showBadge: _aiTip,
              child: TextField(
                controller: _memoController,
                maxLines: 2,
                enabled: !_isAnalyzing,
                decoration: _fieldDecoration(
                  hint: 'AI 분석 시 자동으로 채워져요',
                  aiFilled: _aiTip,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      // 저장 버튼 단일화 — 하단 고정, 이름 없으면 비활성
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
          decoration: BoxDecoration(
            color: c.background,
            border: Border(top: BorderSide(color: c.notTaken)),
          ),
          child: FilledButton(
            onPressed: canSave && !_isAnalyzing ? _save : null,
            style: FilledButton.styleFrom(
              backgroundColor: c.supplement,
              disabledBackgroundColor: c.notTaken,
              foregroundColor: Colors.white,
              disabledForegroundColor: c.textSecondary.withValues(alpha: 0.6),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              textStyle:
                  const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
            ),
            child: const Text('저장하기'),
          ),
        ),
      ),
    );
  }
}

/// AI가 채운 필드 위에 붙는 "AI 입력" 뱃지 래퍼
class _AiTaggedField extends StatelessWidget {
  final bool showBadge;
  final Widget child;

  const _AiTaggedField({required this.showBadge, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!showBadge) return child;
    final c = context.c;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -9,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: c.supplementDark,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 11, color: Colors.white),
                SizedBox(width: 3),
                Text(
                  'AI 입력',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 사진 없을 때 — AI 가치를 설명하는 점선 카드
class _PhotoValueCard extends StatelessWidget {
  final VoidCallback onTap;

  const _PhotoValueCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return CustomPaint(
      painter: _DashedRRectPainter(
        color: c.supplement.withValues(alpha: 0.4),
        radius: 18,
      ),
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: c.supplement.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.photo_camera,
                      color: c.supplementDark, size: 30),
                ),
                const SizedBox(height: 13),
                Text(
                  '사진을 찍어보세요',
                  style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary),
                ),
                const SizedBox(height: 5),
                Text(
                  '통 사진 한 장이면 AI가 이름·복용 시간·팁을\n자동으로 채워줘요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12, color: c.textSecondary, height: 1.55),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 사진 등록 후 — 분석 상태 카드 (분석 중 / 완료 / 등록됨 + 다시 분석)
class _PhotoStatusCard extends StatelessWidget {
  final String imagePath;
  final bool isAnalyzing;
  final bool analyzed;
  final VoidCallback onChangePhoto;
  final VoidCallback onReanalyze;

  const _PhotoStatusCard({
    required this.imagePath,
    required this.isAnalyzing,
    required this.analyzed,
    required this.onChangePhoto,
    required this.onReanalyze,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          InkWell(
            customBorder: const CircleBorder(),
            onTap: isAnalyzing ? null : onChangePhoto,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipOval(
                  child: Image.file(
                    File(imagePath),
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: c.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(Icons.photo_camera,
                        size: 13, color: c.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isAnalyzing)
                      SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: c.supplementDark),
                      )
                    else
                      Icon(
                        analyzed ? Icons.auto_awesome : Icons.photo_camera,
                        size: 15,
                        color: c.supplementDark,
                      ),
                    const SizedBox(width: 5),
                    Text(
                      isAnalyzing
                          ? 'AI 분석 중...'
                          : analyzed
                              ? 'AI 분석 완료'
                              : '사진 등록됨',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: c.supplementDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isAnalyzing ? '이름·복용 시간·팁을 채우고 있어요' : '사진을 바꾸면 다시 분석해요',
                  style: TextStyle(
                      fontSize: 11.5, color: c.textSecondary, height: 1.5),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: isAnalyzing ? null : onReanalyze,
            child: Text(
              '다시 분석',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: c.primaryDark),
            ),
          ),
        ],
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
