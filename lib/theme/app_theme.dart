import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── 라이트 팔레트 고정값 (하위 호환 & const 컨텍스트 전용) ──────────
class AppColors {
  static const primary = Color(0xFF4FC3F7);
  static const primaryDark = Color(0xFF0288D1);
  static const supplement = Color(0xFF81C784);
  static const supplementDark = Color(0xFF388E3C);
  static const background = Color(0xFFF5F9FF);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B7280);
  static const taken = Color(0xFF4CAF50);
  static const notTaken = Color(0xFFE0E0E0);
}

// ─── 테마 확장: 밝기별 시맨틱 색상 ─────────────────────────────────
class AppPalette extends ThemeExtension<AppPalette> {
  final Color primary;
  final Color primaryDark;
  final Color supplement;
  final Color supplementDark;
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color taken;
  final Color notTaken;

  const AppPalette({
    required this.primary,
    required this.primaryDark,
    required this.supplement,
    required this.supplementDark,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.taken,
    required this.notTaken,
  });

  static const light = AppPalette(
    primary: Color(0xFF4FC3F7),
    primaryDark: Color(0xFF0288D1),
    supplement: Color(0xFF81C784),
    supplementDark: Color(0xFF388E3C),
    background: Color(0xFFF5F9FF),
    surface: Colors.white,
    textPrimary: Color(0xFF1A1A2E),
    textSecondary: Color(0xFF6B7280),
    taken: Color(0xFF4CAF50),
    notTaken: Color(0xFFE0E0E0),
  );

  static const dark = AppPalette(
    primary: Color(0xFF4FC3F7),
    primaryDark: Color(0xFF4FC3F7),
    supplement: Color(0xFF81C784),
    supplementDark: Color(0xFF81C784),
    background: Color(0xFF0E1116),
    surface: Color(0xFF1A2029),
    textPrimary: Color(0xFFECEFF4),
    textSecondary: Color(0xFF9AA4B2),
    taken: Color(0xFF66BB6A),
    notTaken: Color(0xFF3A4049),
  );

  @override
  AppPalette copyWith({
    Color? primary,
    Color? primaryDark,
    Color? supplement,
    Color? supplementDark,
    Color? background,
    Color? surface,
    Color? textPrimary,
    Color? textSecondary,
    Color? taken,
    Color? notTaken,
  }) {
    return AppPalette(
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      supplement: supplement ?? this.supplement,
      supplementDark: supplementDark ?? this.supplementDark,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      taken: taken ?? this.taken,
      notTaken: notTaken ?? this.notTaken,
    );
  }

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      supplement: Color.lerp(supplement, other.supplement, t)!,
      supplementDark: Color.lerp(supplementDark, other.supplementDark, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      taken: Color.lerp(taken, other.taken, t)!,
      notTaken: Color.lerp(notTaken, other.notTaken, t)!,
    );
  }
}

// ─── BuildContext 단축 확장 ──────────────────────────────────────
extension AppColorsX on BuildContext {
  AppPalette get c => Theme.of(this).extension<AppPalette>()!;
}

// ─── 라이트 테마 ─────────────────────────────────────────────────
ThemeData buildLightTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimary),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    extensions: const [AppPalette.light],
  );
}

// ─── 다크 테마 ───────────────────────────────────────────────────
ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppPalette.dark.primary,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: AppPalette.dark.background,
    appBarTheme: AppBarTheme(
      backgroundColor: AppPalette.dark.background,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppPalette.dark.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: AppPalette.dark.textPrimary),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppPalette.dark.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    extensions: const [AppPalette.dark],
  );
}
