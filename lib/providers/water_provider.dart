import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/water_log.dart';

final waterGoalProvider = StateNotifierProvider<WaterGoalNotifier, int>((ref) {
  return WaterGoalNotifier();
});

class WaterGoalNotifier extends StateNotifier<int> {
  WaterGoalNotifier() : super(2000) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt('waterGoal') ?? 2000;
  }

  Future<void> setGoal(int ml) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('waterGoal', ml);
    state = ml;
  }
}

final waterAmountProvider = StateNotifierProvider<WaterAmountNotifier, int>((ref) {
  return WaterAmountNotifier();
});

class WaterAmountNotifier extends StateNotifier<int> {
  WaterAmountNotifier() : super(0) {
    loadToday();
  }

  final _db = DbHelper();

  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> loadToday() async {
    state = await _db.getTodayWaterTotal(_todayKey);
  }

  Future<void> add(int ml) async {
    await _db.logWater(ml);
    state = state + ml;
  }

  Future<void> undoLast() async {
    await _db.deleteLastWaterLog(_todayKey);
    state = await _db.getTodayWaterTotal(_todayKey);
  }

  Future<List<WaterLog>> getTodayLogs() async {
    return _db.getWaterLogs(_todayKey);
  }
}

final waterCupSizeProvider = StateNotifierProvider<WaterCupSizeNotifier, int>((ref) {
  return WaterCupSizeNotifier();
});

class WaterCupSizeNotifier extends StateNotifier<int> {
  WaterCupSizeNotifier() : super(250) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt('cupSize') ?? 250;
  }

  Future<void> setCupSize(int ml) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('cupSize', ml);
    state = ml;
  }
}
