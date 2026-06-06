import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class NotiSetting {
  final bool enabled;
  final int hour;
  final int minute;

  const NotiSetting({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  NotiSetting copyWith({bool? enabled, int? hour, int? minute}) => NotiSetting(
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
      );

  TimeOfDay get timeOfDay => TimeOfDay(hour: hour, minute: minute);
}

class NotificationState {
  final NotiSetting water;
  final NotiSetting morning;
  final NotiSetting lunch;
  final NotiSetting dinner;
  final NotiSetting bedtime;

  const NotificationState({
    required this.water,
    required this.morning,
    required this.lunch,
    required this.dinner,
    required this.bedtime,
  });

  NotificationState copyWith({
    NotiSetting? water,
    NotiSetting? morning,
    NotiSetting? lunch,
    NotiSetting? dinner,
    NotiSetting? bedtime,
  }) =>
      NotificationState(
        water: water ?? this.water,
        morning: morning ?? this.morning,
        lunch: lunch ?? this.lunch,
        dinner: dinner ?? this.dinner,
        bedtime: bedtime ?? this.bedtime,
      );

  NotiSetting supplement(String mealTime) => switch (mealTime) {
        'morning' => morning,
        'lunch' => lunch,
        'dinner' => dinner,
        'bedtime' => bedtime,
        _ => morning,
      };
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>(
        (ref) => NotificationNotifier());

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier()
      : super(const NotificationState(
          water: NotiSetting(enabled: false, hour: 10, minute: 0),
          morning: NotiSetting(enabled: false, hour: 8, minute: 0),
          lunch: NotiSetting(enabled: false, hour: 12, minute: 0),
          dinner: NotiSetting(enabled: false, hour: 18, minute: 0),
          bedtime: NotiSetting(enabled: false, hour: 22, minute: 0),
        )) {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = NotificationState(
      water: NotiSetting(
        enabled: p.getBool('noti_water_enabled') ?? false,
        hour: p.getInt('noti_water_hour') ?? 10,
        minute: p.getInt('noti_water_minute') ?? 0,
      ),
      morning: NotiSetting(
        enabled: p.getBool('noti_morning_enabled') ?? false,
        hour: p.getInt('noti_morning_hour') ?? 8,
        minute: p.getInt('noti_morning_minute') ?? 0,
      ),
      lunch: NotiSetting(
        enabled: p.getBool('noti_lunch_enabled') ?? false,
        hour: p.getInt('noti_lunch_hour') ?? 12,
        minute: p.getInt('noti_lunch_minute') ?? 0,
      ),
      dinner: NotiSetting(
        enabled: p.getBool('noti_dinner_enabled') ?? false,
        hour: p.getInt('noti_dinner_hour') ?? 18,
        minute: p.getInt('noti_dinner_minute') ?? 0,
      ),
      bedtime: NotiSetting(
        enabled: p.getBool('noti_bedtime_enabled') ?? false,
        hour: p.getInt('noti_bedtime_hour') ?? 22,
        minute: p.getInt('noti_bedtime_minute') ?? 0,
      ),
    );
  }

  Future<void> updateWater(NotiSetting noti) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('noti_water_enabled', noti.enabled);
    await p.setInt('noti_water_hour', noti.hour);
    await p.setInt('noti_water_minute', noti.minute);
    state = state.copyWith(water: noti);
    await NotificationService.scheduleWater(noti.enabled, noti.hour, noti.minute);
  }

  Future<void> updateSupplement(String mealTime, NotiSetting noti) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('noti_${mealTime}_enabled', noti.enabled);
    await p.setInt('noti_${mealTime}_hour', noti.hour);
    await p.setInt('noti_${mealTime}_minute', noti.minute);
    state = switch (mealTime) {
      'morning' => state.copyWith(morning: noti),
      'lunch' => state.copyWith(lunch: noti),
      'dinner' => state.copyWith(dinner: noti),
      'bedtime' => state.copyWith(bedtime: noti),
      _ => state,
    };
    await NotificationService.scheduleSupplement(
        mealTime, noti.enabled, noti.hour, noti.minute);
  }
}
