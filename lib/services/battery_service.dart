import 'package:flutter/services.dart';

/// 배터리 최적화 예외 상태 조회·요청.
/// vivo 등 일부 제조사는 백그라운드 앱을 수 초 만에 freeze하면서 알람
/// 브로드캐스트를 앱이 깨어날 때까지 지연시킨다. 배터리 최적화 예외로
/// 등록해야 알림이 설정한 시각에 도착한다.
class BatteryService {
  static const _channel = MethodChannel('com.p2bble.haru_1min/battery');

  static Future<bool> isIgnoringOptimizations() async {
    try {
      return await _channel.invokeMethod<bool>(
              'isIgnoringBatteryOptimizations') ??
          false;
    } catch (_) {
      return true; // 조회 실패 시 안내 카드를 띄우지 않는 쪽으로
    }
  }

  static Future<void> requestIgnoreOptimizations() async {
    try {
      await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (_) {}
  }
}
