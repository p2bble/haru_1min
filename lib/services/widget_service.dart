import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';

class WidgetService {
  static Future<void> init() async {
    await HomeWidget.setAppGroupId('com.p2bble.haru_1min');
    await HomeWidget.registerInteractivityCallback(backgroundCallback);
  }

  static Future<void> update({
    required int waterAmount,
    required int waterGoal,
    required int cupSize,
    required int supplementTaken,
    required int supplementTotal,
  }) async {
    await Future.wait([
      HomeWidget.saveWidgetData('water_amount', waterAmount),
      HomeWidget.saveWidgetData('water_goal', waterGoal),
      HomeWidget.saveWidgetData('cup_size', cupSize),
      HomeWidget.saveWidgetData('supplement_taken', supplementTaken),
      HomeWidget.saveWidgetData('supplement_total', supplementTotal),
      // 자정이 지나면 위젯(네이티브)이 이 키를 보고 0으로 표시
      HomeWidget.saveWidgetData(
          'water_date', DateFormat('yyyy-MM-dd').format(DateTime.now())),
    ]);
    await HomeWidget.updateWidget(androidName: 'HaruWidget');
  }

  /// DB·설정값을 직접 읽어 위젯을 갱신. 알림 액션 등 provider가 없는
  /// 백그라운드 컨텍스트에서 사용한다.
  static Future<void> updateFromDb() async {
    final db = DbHelper();
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final total = await db.getTodayWaterTotal(todayKey);
    final supplements = await db.getActiveSupplements();
    final takenIds = (await db.getTakenSupplementIds(todayKey)).toSet();
    final prefs = await SharedPreferences.getInstance();
    await update(
      waterAmount: total,
      waterGoal: prefs.getInt('waterGoal') ?? 2000,
      cupSize: prefs.getInt('cupSize') ?? 250,
      supplementTaken:
          supplements.where((s) => takenIds.contains(s.id)).length,
      supplementTotal: supplements.length,
    );
  }
}

// 위젯 버튼 탭 시 Flutter background에서 실행되는 콜백
@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  if (uri?.host == 'add_water') {
    final db = DbHelper();
    final cupSize = int.tryParse(uri?.queryParameters['cup_size'] ?? '250') ?? 250;
    await db.logWater(cupSize);

    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final total = await db.getTodayWaterTotal(todayKey);
    await HomeWidget.saveWidgetData('water_amount', total);
    await HomeWidget.saveWidgetData('water_date', todayKey);
    await HomeWidget.updateWidget(androidName: 'HaruWidget');
  }
}
