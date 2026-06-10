import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
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
