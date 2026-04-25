/// 大图标按钮组件
/// 无障碍设计：最小尺寸 >= 80x80dp，高对比度
library;

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/vibration_util.dart';

/// 大图标按钮
/// 用于主要操作，确保足够大的点击区域
class LargeIconButton extends StatelessWidget {
  /// 按钮图标
  final IconData icon;
  /// 按钮文字标签
  final String label;
  /// 点击回调
  final VoidCallback? onPressed;
  /// 按钮背景色
  final Color? backgroundColor;
  /// 按钮文字颜色
  final Color? textColor;
  /// 按钮尺寸（正方形边长）
  final double size;
  /// 是否显示文字标签
  final bool showLabel;
  /// 震动反馈强度
  final VibrationStrength vibration;

  const LargeIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.size = AppDimensions.primaryButtonSize,
    this.showLabel = true,
    this.vibration = VibrationStrength.light,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.primaryGreen;
    final txtColor = textColor ?? AppColors.textOnPrimary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: ElevatedButton(
            onPressed: () {
              // 触发震动反馈
              _triggerVibration();
              onPressed?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: bgColor,
              foregroundColor: txtColor,
              minimumSize: Size(size, size),
              maximumSize: Size(size, size),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusMedium),
              ),
              elevation: 4,
              disabledBackgroundColor: bgColor.withOpacity(0.5),
              disabledForegroundColor: txtColor.withOpacity(0.5),
            ),
            child: Icon(
              icon,
              size: size * 0.45,
              color: txtColor,
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: AppDimensions.spacingSmall),
          SizedBox(
            width: size + 16,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  /// 触发震动反馈
  void _triggerVibration() {
    switch (vibration) {
      case VibrationStrength.light:
        VibrationUtil.light();
        break;
      case VibrationStrength.medium:
        VibrationUtil.medium();
        break;
      case VibrationStrength.heavy:
        VibrationUtil.heavy();
        break;
      case VibrationStrength.none:
        break;
    }
  }
}

/// 震动强度枚举
enum VibrationStrength {
  /// 无震动
  none,
  /// 轻触
  light,
  /// 中等
  medium,
  /// 重度
  heavy,
}
