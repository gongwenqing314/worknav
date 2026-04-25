/// 绿色大勾按钮
/// 完成当前步骤的主要操作按钮，大尺寸、高对比度
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/vibration_util.dart';

/// 绿色大勾按钮
/// 任务执行页面中完成当前步骤的主要操作按钮
class CompleteButton extends StatelessWidget {
  /// 点击回调
  final VoidCallback? onPressed;
  /// 按钮文字
  final String text;
  /// 是否禁用
  final bool isEnabled;

  const CompleteButton({
    super.key,
    this.onPressed,
    this.text = '完成了',
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 100,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.pagePadding,
        ),
        child: ElevatedButton(
          onPressed: isEnabled
              ? () {
                  VibrationUtil.medium();
                  onPressed?.call();
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: AppColors.textOnPrimary,
            disabledBackgroundColor: AppColors.primaryGreen.withOpacity(0.4),
            disabledForegroundColor: AppColors.textOnPrimary.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
            ),
            elevation: isEnabled ? 6 : 0,
            shadowColor: isEnabled
                ? AppColors.primaryGreen.withOpacity(0.3)
                : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 大勾图标
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.textOnPrimary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 32,
                  color: AppColors.textOnPrimary,
                ),
              ),
              const SizedBox(width: 16),
              // 按钮文字
              Text(
                text,
                style: AppTextStyles.buttonLarge.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
