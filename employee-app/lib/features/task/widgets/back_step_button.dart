/// 返回上一步按钮
/// 允许用户回看已完成的步骤，不重复计数
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/vibration_util.dart';

/// 返回上一步按钮
/// 允许用户回看已完成的步骤内容
class BackStepButton extends StatelessWidget {
  /// 点击回调
  final VoidCallback? onPressed;
  /// 是否可以返回（第一步时不可返回）
  final bool canGoBack;

  const BackStepButton({
    super.key,
    this.onPressed,
    this.canGoBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.pagePadding,
        ),
        child: OutlinedButton(
          onPressed: canGoBack
              ? () {
                  VibrationUtil.light();
                  onPressed?.call();
                }
              : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            disabledForegroundColor: AppColors.textHint,
            side: BorderSide(
              color: canGoBack
                  ? AppColors.textSecondary
                  : AppColors.divider,
              width: 2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.arrow_back,
                size: 28,
                color: canGoBack
                    ? AppColors.textSecondary
                    : AppColors.textHint,
              ),
              const SizedBox(width: 8),
              Text(
                '看上一步',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: canGoBack
                      ? AppColors.textSecondary
                      : AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
