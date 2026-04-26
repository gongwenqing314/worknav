/// 应用主题 - 高对比度、大字体无障碍主题
library;

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class AppTheme {
  AppTheme._();

  /// 浅色主题（默认）
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.primaryGreen,
        brightness: Brightness.light,

        // 色彩方案
        colorScheme: const ColorScheme.light(
          primary: AppColors.primaryGreen,
          onPrimary: AppColors.textOnPrimary,
          primaryContainer: AppColors.primaryGreenLight,
          onPrimaryContainer: AppColors.primaryGreenDark,
          secondary: AppColors.primaryBlue,
          onSecondary: AppColors.textOnPrimary,
          secondaryContainer: AppColors.primaryBlueLight,
          onSecondaryContainer: AppColors.primaryBlueDark,
          error: AppColors.primaryRed,
          onError: AppColors.textOnPrimary,
          errorContainer: AppColors.primaryRedLight,
          onErrorContainer: AppColors.primaryRedDark,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          outline: AppColors.divider,
        ),

        // 脚手架背景色
        scaffoldBackgroundColor: AppColors.background,

        // AppBar 主题
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        // 卡片主题
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: AppColors.shadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),

        // 文字主题
        textTheme: const TextTheme(
          headlineLarge: AppTextStyles.headlineLarge,
          headlineMedium: AppTextStyles.headlineMedium,
          headlineSmall: AppTextStyles.headlineSmall,
          bodyLarge: AppTextStyles.bodyLarge,
          bodyMedium: AppTextStyles.bodyMedium,
          bodySmall: AppTextStyles.bodySmall,
          labelLarge: AppTextStyles.buttonLarge,
          labelMedium: AppTextStyles.buttonMedium,
        ),

        // 按钮主题
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(80, 80),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            textStyle: AppTextStyles.buttonLarge,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            minimumSize: const Size(64, 56),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            textStyle: AppTextStyles.buttonMedium,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(64, 56),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            textStyle: AppTextStyles.buttonMedium,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: const BorderSide(
              color: AppColors.primaryGreen,
              width: 2,
            ),
          ),
        ),

        // 底部导航栏主题
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primaryGreen,
          unselectedItemColor: AppColors.textHint,
          selectedLabelStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
        ),

        // 分隔线主题
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
          space: 1,
        ),

        // 输入框主题
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.primaryGreen,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          hintStyle: AppTextStyles.hint,
        ),

        // 对话框主题
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titleTextStyle: AppTextStyles.headlineMedium,
          contentTextStyle: AppTextStyles.bodyMedium,
        ),

        // SnackBar 主题
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentTextStyle: AppTextStyles.bodyMedium,
        ),
      );
}
