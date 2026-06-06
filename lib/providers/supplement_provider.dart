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
  }

  final _db = DbHelper();

  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> loadToday() async {
    final ids = await _db.getTakenSupplementIds(_todayKey);
    state = ids.toSet();
  }

  Future<void> toggle(int supplementId) async {
    if (state.contains(supplementId)) {
      await _db.removeSupplementLog(supplementId, _todayKey);
      state = {...state}..remove(supplementId);
    } else {
      await _db.logSupplement(supplementId);
      state = {...state, supplementId};
    }
  }
}
