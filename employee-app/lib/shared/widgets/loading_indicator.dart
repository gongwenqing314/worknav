/// 加载指示器组件
/// 无障碍友好的加载状态展示
library;

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// 加载指示器
/// 显示加载中的状态，附带提示文字
class LoadingIndicator extends StatelessWidget {
  /// 加载提示文字
  final String? message;
  /// 指示器颜色
  final Color? color;
  /// 指示器大小
  final double size;

  const LoadingIndicator({
    super.key,
    this.message,
    this.color,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final indicatorColor = color ?? AppColors.primaryGreen;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 6,
              valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// 带错误状态的重试组件
class LoadingRetry extends StatelessWidget {
  /// 错误提示文字
  final String message;
  /// 重试回调
  final VoidCallback onRetry;
  /// 重试按钮文字
  final String retryText;

  const LoadingRetry({
    super.key,
    required this.message,
    required this.onRetry,
    this.retryText = '重试',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.primaryRed,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 160,
              height: 56,
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: AppColors.textOnPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  retryText,
                  style: AppTextStyles.buttonLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
