import 'dart:async';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'database/db_helper.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/widget_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  await FirebaseAppCheck.instance.activate(
    androidProvider: kReleaseMode
        ? AndroidProvider.playIntegrity
        : AndroidProvider.debug,
  );
  await WidgetService.init();
  await NotificationService.init();
  // 캐시에 저장된 기존 사진 구출 — 시작을 막지 않도록 비동기 실행 (멱등)
  unawaited(DbHelper().migrateLegacyImages());
  runApp(const ProviderScope(child: HaruApp()));
}

class HaruApp extends ConsumerWidget {
  const HaruApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: '하루 1분',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      home: const HomeScreen(),
    );
  }
}
