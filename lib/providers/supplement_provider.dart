import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/supplement.dart';

final supplementListProvider =
    StateNotifierProvider<SupplementListNotifier, List<Supplement>>((ref) {
  return SupplementListNotifier();
});

class SupplementListNotifier extends StateNotifier<List<Supplement>> {
  SupplementListNotifier() : super([]) {
    load();
  }

  final _db = DbHelper();

  Future<void> load() async {
    state = await _db.getActiveSupplements();
  }

  Future<void> add(Supplement s) async {
    final id = await _db.insertSupplement(s);
    state = [...state, s.copyWith(id: id)];
  }

  Future<void> remove(int id) async {
    await _db.deleteSupplement(id);
    state = state.where((s) => s.id != id).toList();
  }

  Future<void> update(Supplement s) async {
    await _db.updateSupplement(s);
    state = state.map((e) => e.id == s.id ? s : e).toList();
  }
}

final takenSupplementIdsProvider =
    StateNotifierProvider<TakenSupplementIdsNotifier, Set<int>>((ref) {
  return TakenSupplementIdsNotifier();
});

class TakenSupplementIdsNotifier extends StateNotifier<Set<int>> {
  TakenSupplementIdsNotifier() : super({}) {
    loadToday();
    _scheduleMidnightReload();
  }

  final _db = DbHelper();

  /// 현재 state가 가리키는 날짜('yyyy-MM-dd'). 자정을 넘겼는지 판단하는 기준.
  String? _loadedDate;
  Timer? _midnightTimer;

  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  /// 다음 자정에 복용 체크 상태를 새 날짜 기준으로 다시 로드하도록 예약.
  void _scheduleMidnightReload() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(nextMidnight.difference(now), () {
      loadToday();
      _scheduleMidnightReload();
    });
  }

  Future<void> loadToday() async {
    _loadedDate = _todayKey;
    final ids = await _db.getTakenSupplementIds(_loadedDate!);
    state = ids.toSet();
  }

  /// 시간대 "모두 체크" — 아직 안 먹은 것만 한 번에 복용 처리
  Future<void> takeAll(Iterable<int> supplementIds) async {
    if (_todayKey != _loadedDate) {
      await loadToday();
    }
    final toTake =
        supplementIds.where((id) => !state.contains(id)).toList();
    for (final id in toTake) {
      await _db.logSupplement(id);
    }
    if (toTake.isNotEmpty) state = {...state, ...toTake};
  }

  Future<void> toggle(int supplementId) async {
    final today = _todayKey;
    if (today != _loadedDate) {
      // 자정을 넘김 — 새 날짜 기준으로 다시 로드한 뒤 처리
      await loadToday();
    }
    if (state.contains(supplementId)) {
      await _db.removeSupplementLog(supplementId, today);
      state = {...state}..remove(supplementId);
    } else {
      await _db.logSupplement(supplementId);
      state = {...state, supplementId};
    }
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }
}
