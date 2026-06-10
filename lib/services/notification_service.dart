import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const int _waterNotiId = 0;
  static const Map<String, int> _suppIds = {
    'morning': 1,
    'lunch': 2,
    'dinner': 3,
    'bedtime': 4,
  };
  static const Map<String, String> _suppLabels = {
    'morning': '아침',
    'lunch': '점심',
    'dinner': '저녁',
    'bedtime': '자기 전',
  };

  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  }

  static Future<bool> requestPermission() async {
    return await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission() ??
        false;
  }

  /// Android 14+는 정확 알람(SCHEDULE_EXACT_ALARM)이 기본 거부라
  /// 그대로 예약하면 PlatformException이 발생한다.
  /// 리마인더는 분 단위 정밀도가 필요 없으므로 inexact로 폴백한다.
  static Future<AndroidScheduleMode> _scheduleMode() async {
    final canExact = await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.canScheduleExactNotifications() ??
        false;
    return canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  static Future<void> scheduleWater(bool enabled, int hour, int minute) async {
    await _plugin.cancel(_waterNotiId);
    if (!enabled) return;
    await _plugin.zonedSchedule(
      _waterNotiId,
      '물 마실 시간이에요 💧',
      '오늘 목표를 향해 한 잔 더!',
      _nextDaily(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'water_ch',
          '물 알림',
          channelDescription: '물 마시기 리마인더',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: await _scheduleMode(),
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> scheduleSupplement(
      String mealTime, bool enabled, int hour, int minute) async {
    final id = _suppIds[mealTime]!;
    await _plugin.cancel(id);
    if (!enabled) return;
    await _plugin.zonedSchedule(
      id,
      '${_suppLabels[mealTime]} 영양제 챙기세요 💊',
      '하루 1분이면 충분해요!',
      _nextDaily(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'supp_ch',
          '영양제 알림',
          channelDescription: '영양제 복용 리마인더',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: await _scheduleMode(),
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static tz.TZDateTime _nextDaily(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var t =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (t.isBefore(now)) t = t.add(const Duration(days: 1));
    return t;
  }
}
