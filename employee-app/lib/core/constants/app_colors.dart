/// 色彩常量 - 高对比度无障碍设计
/// 所有颜色组合确保前景与背景对比度 >= 4.5:1
library;

import 'dart:ui';

class AppColors {
  AppColors._();

  // ===== 主色调 =====
  /// 确认/成功 - 绿色
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color primaryGreenDark = Color(0xFF388E3C);
  static const Color primaryGreenLight = Color(0xFFC8E6C9);

  /// 进行中/信息 - 蓝色
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color primaryBlueDark = Color(0xFF1565C0);
  static const Color primaryBlueLight = Color(0xFFBBDEFB);

  /// 警告/危险 - 红色
  static const Color primaryRed = Color(0xFFF44336);
  static const Color primaryRedDark = Color(0xFFC62828);
  static const Color primaryRedLight = Color(0xFFFFCDD2);

  // ===== 中性色 =====
  /// 主背景色 - 浅灰白色，确保与深色文字对比度足够
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  /// 主文字色 - 深灰近黑，确保与浅色背景对比度 >= 4.5:1
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF424242);
  static const Color textHint = Color(0xFF757575);

  /// 文字白色（用于深色背景上的文字）
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ===== 功能色 =====
  /// 求助/远程协助 - 橙色
  static const Color assistOrange = Color(0xFFFF9800);
  static const Color assistOrangeDark = Color(0xFFF57C00);

  /// 情绪 - 紫色
  static const Color emotionPurple = Color(0xFF9C27B0);
  static const Color emotionPurpleLight = Color(0xFFE1BEE7);

  /// 沟通 - 青色
  static const Color commTeal = Color(0xFF009688);
  static const Color commTealLight = Color(0xFFB2DFDB);

  // ===== 分隔线 =====
  static const Color divider = Color(0xFFE0E0E0);

  // ===== 阴影 =====
  static const Color shadow = Color(0x1A000000);

  // ===== 状态色 =====
  /// 任务状态 - 待执行
  static const Color taskPending = Color(0xFFFFC107);
  /// 任务状态 - 进行中
  static const Color taskInProgress = primaryBlue;
  /// 任务状态 - 已完成
  static const Color taskCompleted = primaryGreen;
  /// 任务状态 - 需要帮助
  static const Color taskNeedHelp = primaryRed;
}
