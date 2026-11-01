import 'package:flutter/material.dart';

/// 全局配色：米白底 + 墨绿主色 + 陶土色点缀
/// 走「高级简约」路线，不用大面积高饱和色，长时间背词不刺眼
class AppColors {
  static const bg = Color(0xFFFAF9F6); // 页面底色
  static const surface = Color(0xFFFFFFFF); // 卡片
  static const ink = Color(0xFF1C1C1A); // 主文字
  static const muted = Color(0xFF8C8C84); // 次要文字
  static const line = Color(0xFFE9E7E0); // 分割线
  static const primary = Color(0xFF1F4B43); // 墨绿，主按钮
  static const accent = Color(0xFFB4673F); // 陶土色，强调
  static const ok = Color(0xFF2E7D5B); // 答对
  static const bad = Color(0xFFB03A2E); // 答错
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.surface,
    ),
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.ink,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    dividerColor: AppColors.line,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    // 开关颜色交给 Material 3 主题推导，避免不同 Flutter 版本的 API 差异
  );
}
