/// 情绪确认对话框
/// 选择消极情绪后弹出确认对话框，通知管理员
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/vibration_util.dart';

/// 情绪确认对话框
/// 当用户选择消极情绪时，弹出确认对话框
/// 确认后会通知管理员关注
class EmotionConfirmDialog extends StatelessWidget {
  /// 情绪名称
  final String emotionName;
  /// 确认回调
  final VoidCallback? onConfirm;
  /// 取消回调
  final VoidCallback? onCancel;

  const EmotionConfirmDialog({
    super.key,
    required this.emotionName,
    this.onConfirm,
    this.onCancel,
  });

  /// 显示确认对话框
  static Future<bool?> show(
    BuildContext context, {
    required String emotionName,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EmotionConfirmDialog(
        emotionName: emotionName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      title: Row(
        children: [
          const Icon(
            Icons.favorite,
            color: AppColors.primaryRed,
            size: 32,
          ),
          const SizedBox(width: 12),
          Text(
            '你感觉怎么样？',
            style: AppTextStyles.headlineSmall,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '你选择了"$emotionName"。',
            style: AppTextStyles.bodyLarge,
          ),
          const SizedBox(height: 12),
          Text(
            '我们会通知管理员来关心你。你确定吗？',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        // 取消按钮
        SizedBox(
          width: 120,
          height: 56,
          child: OutlinedButton(
            onPressed: () {
              VibrationUtil.light();
              Navigator.of(context).pop(false);
              onCancel?.call();
            },
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: const BorderSide(color: AppColors.divider, width: 2),
            ),
            child: Text(
              '再想想',
              style: AppTextStyles.buttonMedium,
            ),
          ),
        ),
        // 确认按钮
        SizedBox(
          width: 120,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              VibrationUtil.medium();
              Navigator.of(context).pop(true);
              onConfirm?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: AppColors.textOnPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              '确定',
              style: AppTextStyles.buttonLarge.copyWith(
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
