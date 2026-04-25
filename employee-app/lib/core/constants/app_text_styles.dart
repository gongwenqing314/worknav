/// 字体样式常量 - 大字体无障碍设计
/// 所有字体尺寸符合无障碍标准
library;

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ===== 标题样式 =====
  /// 大标题 - 用于页面标题，>= 28sp
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /// 中标题 - 用于区域标题，>= 24sp
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /// 小标题 - 用于卡片标题，>= 22sp
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // ===== 正文样式 =====
  /// 大正文 - 用于重要说明文字，>= 22sp
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// 标准正文 - 用于一般内容，>= 20sp
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// 小正文 - 用于辅助说明，>= 18sp
  static const TextStyle bodySmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // ===== 按钮文字样式 =====
  /// 主按钮文字 - >= 22sp，白色（用于深色背景按钮）
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textOnPrimary,
    height: 1.2,
  );

  /// 次要按钮文字 - >= 20sp
  static const TextStyle buttonMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  // ===== 特殊样式 =====
  /// 步骤编号 - 超大字体，用于步骤指示
  static const TextStyle stepNumber = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryBlue,
    height: 1.2,
  );

  /// 全屏展示文字 - 应急卡片等场景使用
  static const TextStyle fullScreenText = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /// 问候语文字
  static const TextStyle greeting = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /// 提示文字
  static const TextStyle hint = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    color: AppColors.textHint,
    height: 1.4,
  );
}
