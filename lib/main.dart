import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'database/db_helper.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/widget_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko', null);
  await WidgetService.init();
  await NotificationService.init();
  // 캐시에 저장된 기존 사진 구출 — 시작을 막지 않도록 비동기 실행 (멱등)
  unawaited(DbHelper().migrateLegacyImages());
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ProviderScope(child: HaruApp()));
}

class HaruApp extends StatelessWidget {
  const HaruApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '하루 1분',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const HomeScreen(),
    );
  }
}
