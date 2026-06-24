import 'dart:async';

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
    _scheduleMidnightReload();
  }

  final _db = DbHelper();

  /// 현재 state가 가리키는 날짜('yyyy-MM-dd'). 자정을 넘겼는지 판단하는 기준.
  String? _loadedDate;
  Timer? _midnightTimer;

  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  /// 다음 자정에 오늘 합계를 0부터 다시 로드하도록 예약.
  /// 앱을 켜둔 채 날짜가 바뀌면 어제 값이 그대로 남는 문제를 막는다.
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
    state = await _db.getTodayWaterTotal(_loadedDate!);
  }

  Future<void> add(int ml) async {
    await _db.logWater(ml);
    if (_todayKey != _loadedDate) {
      // 자정을 넘김 — 어제 누적값에 더하지 않고 새 날짜 합계로 다시 로드
      await loadToday();
    } else {
      state = state + ml;
    }
  }

  Future<void> undoLast() async {
    await _db.deleteLastWaterLog(_todayKey);
    await loadToday();
  }

  Future<List<WaterLog>> getTodayLogs() async {
    return _db.getWaterLogs(_todayKey);
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
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
