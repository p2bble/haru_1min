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
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameController.text = widget.existing!.name;
      _memoController.text = widget.existing!.memo ?? '';
      _selectedMealTime = widget.existing!.mealTime;
      _imagePath = widget.existing!.imagePath;
    }
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
    if (_imagePath == null) return;
    setState(() => _isAnalyzing = true);
    final result = await SupplementAiService.analyze(File(_imagePath!));
    if (!mounted) return;
    setState(() => _isAnalyzing = false);

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('분석에 실패했어요. 네트워크를 확인하고 다시 시도해주세요.')),
      );
      return;
    }
    setState(() {
      if (result.name != null && result.name!.isNotEmpty) {
        _nameController.text = result.name!;
      }
      _selectedMealTime = result.mealTime;
      if (result.tip != null && result.tip!.isNotEmpty) {
        _memoController.text = result.tip!;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'AI 분석 완료! ${mealTimeLabels[result.mealTime]} 복용을 추천해요.'),
        duration: const Duration(seconds: 3),
      ),
    );
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
      setState(() => _imagePath = saved);
    }
  }

  Future<ImageSource?> _showImageSourceDialog() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const Text('사진 선택', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
            title: const Text('카메라로 찍기'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
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
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('영양제 이름을 입력해주세요')),
      );
      return;
    }

    final memo = _memoController.text.trim();
    if (widget.existing != null) {
      await ref.read(supplementListProvider.notifier).update(
            widget.existing!.copyWith(
              name: name,
              imagePath: _imagePath,
              mealTime: _selectedMealTime,
              memo: memo.isEmpty ? null : memo,
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
              createdAt: DateTime.now(),
            ),
          );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing != null ? '영양제 수정' : '영양제 추가'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('저장', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.supplement.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.supplement.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: _imagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(60),
                          child: Image.file(File(_imagePath!), fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_rounded, color: AppColors.supplement, size: 36),
                            SizedBox(height: 4),
                            Text('사진 추가', style: TextStyle(color: AppColors.supplement, fontSize: 12)),
                          ],
                        ),
                ),
              ),
            ),
            if (_imagePath != null) ...[
              const SizedBox(height: 12),
              Center(
                child: OutlinedButton.icon(
                  onPressed: _isAnalyzing ? null : _analyzeImage,
                  icon: _isAnalyzing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome, size: 16),
                  label: Text(_isAnalyzing ? '분석 중...' : 'AI로 자동 분석'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.supplementDark,
                    side: const BorderSide(color: AppColors.supplement),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
            const Text('영양제 이름', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: '예: 비타민C, 오메가3',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
            const Text('복용 시간', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              children: mealTimeLabels.entries.map((e) {
                final selected = _selectedMealTime == e.key;
                return ChoiceChip(
                  label: Text(e.value),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedMealTime = e.key),
                  selectedColor: AppColors.supplement,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                    color: selected ? AppColors.supplement : AppColors.notTaken,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text('복용 팁 (선택)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _memoController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'AI 분석 시 자동으로 채워져요',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.supplement,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('저장하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
