/// 尺寸常量 - 无障碍设计尺寸规范
/// 确保所有可点击区域足够大，便于心智障碍人士操作
library;

class AppDimensions {
  AppDimensions._();

  // ===== 按钮尺寸 =====
  /// 主要操作按钮最小尺寸 >= 80x80dp
  static const double primaryButtonMinSize = 80.0;
  /// 主要操作按钮推荐尺寸
  static const double primaryButtonSize = 96.0;
  /// 任务卡片图标尺寸 >= 120x120dp
  static const double taskCardIconSize = 120.0;
  /// 底部导航栏图标尺寸
  static const double navIconSize = 64.0;
  /// 小型操作按钮
  static const double smallButtonSize = 56.0;

  // ===== 间距 =====
  /// 操作按钮间距 >= 16dp
  static const double buttonSpacing = 16.0;
  /// 卡片内边距
  static const double cardPadding = 16.0;
  /// 页面内边距
  static const double pagePadding = 20.0;
  /// 元素间小间距
  static const double spacingSmall = 8.0;
  /// 元素间中等间距
  static const double spacingMedium = 16.0;
  /// 元素间大间距
  static const double spacingLarge = 24.0;
  /// 元素间超大间距
  static const double spacingXLarge = 32.0;

  // ===== 圆角 =====
  /// 按钮圆角
  static const double borderRadiusSmall = 8.0;
  /// 卡片圆角
  static const double borderRadiusMedium = 16.0;
  /// 大圆角
  static const double borderRadiusLarge = 24.0;
  /// 圆形
  static const double borderRadiusCircular = 100.0;

  // ===== 卡片尺寸 =====
  /// 任务卡片高度
  static const double taskCardHeight = 160.0;
  /// 情绪卡片高度
  static const double emotionCardHeight = 120.0;
  /// 沟通板按钮高度
  static const double phraseButtonHeight = 100.0;

  // ===== 进度条 =====
  /// 步骤进度条高度
  static const double progressBarHeight = 12.0;

  // ===== 底部导航 =====
  /// 底部导航栏高度
  static const double bottomNavHeight = 80.0;

  // ===== 顶部栏 =====
  /// 顶部安全区域额外高度
  static const double topBarHeight = 60.0;

  // ===== 图标 =====
  /// 标准图标尺寸
  static const double iconSizeStandard = 32.0;
  /// 大图标尺寸
  static const double iconSizeLarge = 48.0;

  // ===== 动画时长 =====
  /// 快速动画
  static const Duration animFast = Duration(milliseconds: 200);
  /// 标准动画
  static const Duration animNormal = Duration(milliseconds: 300);
  /// 慢速动画
  static const Duration animSlow = Duration(milliseconds: 500);

  // ===== 震动时长 =====
  /// 轻触震动
  static const Duration vibrationLight = Duration(milliseconds: 50);
  /// 确认震动
  static const Duration vibrationMedium = Duration(milliseconds: 100);
  /// 警告震动
  static const Duration vibrationHeavy = Duration(milliseconds: 300);
}
