import 'dart:async';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../database/db_helper.dart';
import 'widget_service.dart';

/// 알림 액션 버튼 탭 시 앱을 열지 않고 백그라운드 isolate에서 실행되는 핸들러.
/// 플러그인 채널을 쓰려면 registrant 초기화가 필요하다.
@pragma('vm:entry-point')
Future<void> notificationTapBackground(NotificationResponse response) async {
  DartPluginRegistrant.ensureInitialized();
  await NotificationService.handleResponse(response);
}

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const int _waterNotiId = 0;
  static const int _waterRepeatBase = 100; // 100 + 시각(0~23)
  static const int _snoozeBase = 50; // 50 + 시간대 ID
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

  static const _actionDrink = 'drink';
  static const _actionTakeAll = 'take_all';
  static const _actionSnooze = 'snooze';

  /// 알림 액션이 처리됐음을 UI에 알리는 스트림 (앱 실행 중 상태 갱신용)
  static final StreamController<void> actionHandled =
      StreamController<void>.broadcast();

  static Future<void> init() async {
    tz.initializeTimeZones();
    // 기기 타임존 기준으로 예약해야 해외에서도 설정한 시각에 울린다.
    // 조회 실패 시에만 주 사용층 기준(Asia/Seoul)으로 폴백.
    try {
      final localTz = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTz.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    }
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_stat_notify'),
      ),
      onDidReceiveNotificationResponse: _onForegroundResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  static Future<void> _onForegroundResponse(NotificationResponse r) async {
    await handleResponse(r);
    actionHandled.add(null);
  }

  /// 알림 본문 탭(앱 열기)과 액션 버튼 탭을 공통 처리.
  /// 백그라운드 isolate에서도 호출되므로 UI 상태를 직접 만지지 않는다.
  static Future<void> handleResponse(NotificationResponse r) async {
    switch (r.actionId) {
      case _actionDrink:
        final prefs = await SharedPreferences.getInstance();
        await DbHelper().logWater(prefs.getInt('cupSize') ?? 250);
        await WidgetService.updateFromDb();
      case _actionTakeAll:
        final mealTime = _mealTimeFromPayload(r.payload);
        if (mealTime == null) return;
        final db = DbHelper();
        final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final taken = (await db.getTakenSupplementIds(todayKey)).toSet();
        final supplements = await db.getActiveSupplements();
        for (final s in supplements) {
          if (s.mealTime == mealTime && !taken.contains(s.id)) {
            await db.logSupplement(s.id!);
          }
        }
        await WidgetService.updateFromDb();
      case _actionSnooze:
        final mealTime = _mealTimeFromPayload(r.payload);
        if (mealTime == null) return;
        await _scheduleSupplementSnooze(mealTime);
    }
  }

  static String? _mealTimeFromPayload(String? payload) {
    if (payload == null || !payload.startsWith('supp:')) return null;
    final mealTime = payload.substring(5);
    return _suppIds.containsKey(mealTime) ? mealTime : null;
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

  static NotificationDetails _waterDetails() => const NotificationDetails(
        android: AndroidNotificationDetails(
          'water_ch',
          '물 알림',
          channelDescription: '물 마시기 리마인더',
          importance: Importance.high,
          priority: Priority.high,
          actions: [
            AndroidNotificationAction(
              _actionDrink,
              '한 잔 마셨어요',
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        ),
      );

  static NotificationDetails _suppDetails() => const NotificationDetails(
        android: AndroidNotificationDetails(
          'supp_ch',
          '영양제 알림',
          channelDescription: '영양제 복용 리마인더',
          importance: Importance.high,
          priority: Priority.high,
          actions: [
            AndroidNotificationAction(
              _actionTakeAll,
              '모두 복용 완료',
              showsUserInterface: false,
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              _actionSnooze,
              '30분 뒤 다시',
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        ),
      );

  /// 하루 한 번 모드 (ID 0)와 반복 모드 (ID 100+시각)를 모두 취소
  static Future<void> _cancelWater() async {
    await _plugin.cancel(_waterNotiId);
    for (var h = 0; h < 24; h++) {
      await _plugin.cancel(_waterRepeatBase + h);
    }
  }

  /// 하루 한 번 모드
  static Future<void> scheduleWater(bool enabled, int hour, int minute) async {
    await _cancelWater();
    if (!enabled) return;
    await _scheduleDailyWater(_waterNotiId, hour, minute);
  }

  /// 반복 모드 — 시작~종료 시각 사이를 간격(시간)마다 알림
  static Future<void> scheduleWaterRepeat(
      bool enabled, int startHour, int endHour, int intervalHours) async {
    await _cancelWater();
    if (!enabled) return;
    for (var h = startHour; h <= endHour; h += intervalHours) {
      await _scheduleDailyWater(_waterRepeatBase + h, h, 0);
    }
  }

  static Future<void> _scheduleDailyWater(int id, int hour, int minute) async {
    await _plugin.zonedSchedule(
      id,
      '물 마실 시간이에요 💧',
      '오늘 목표를 향해 한 잔 더!',
      _nextDaily(hour, minute),
      _waterDetails(),
      payload: 'water',
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
      _suppDetails(),
      payload: 'supp:$mealTime',
      androidScheduleMode: await _scheduleMode(),
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// "30분 뒤 다시" — 같은 내용의 일회성 알림을 30분 뒤에 예약.
  /// 백그라운드 isolate에서는 타임존이 초기화돼 있지 않으므로 다시 세팅한다.
  static Future<void> _scheduleSupplementSnooze(String mealTime) async {
    tz.initializeTimeZones();
    try {
      final localTz = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTz.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    }
    await _plugin.zonedSchedule(
      _snoozeBase + _suppIds[mealTime]!,
      '${_suppLabels[mealTime]} 영양제 챙기세요 💊',
      '30분 전에 미뤄둔 알림이에요',
      tz.TZDateTime.now(tz.local).add(const Duration(minutes: 30)),
      _suppDetails(),
      payload: 'supp:$mealTime',
      androidScheduleMode: await _scheduleMode(),
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
