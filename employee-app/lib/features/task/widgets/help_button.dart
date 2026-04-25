/// 求助按钮
/// 任务执行中遇到困难时请求远程协助
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/vibration_util.dart';

/// 求助按钮
/// 在任务执行页面中，当员工遇到困难时可以点击请求帮助
class HelpButton extends StatelessWidget {
  /// 点击回调
  final VoidCallback? onPressed;
  /// 是否正在请求中
  final bool isRequesting;

  const HelpButton({
    super.key,
    this.onPressed,
    this.isRequesting = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.pagePadding,
        ),
        child: ElevatedButton(
          onPressed: isRequesting
              ? null
              : () {
                  VibrationUtil.warningPattern();
                  onPressed?.call();
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryRed,
            foregroundColor: AppColors.textOnPrimary,
            disabledBackgroundColor: AppColors.primaryRed.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
            ),
            elevation: 4,
          ),
          child: isRequesting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.textOnPrimary,
                    strokeWidth: 3,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.help_outline,
                      size: 28,
                      color: AppColors.textOnPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '我需要帮助',
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: AppColors.textOnPrimary,
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
