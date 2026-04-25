/// 拍照按钮组件
/// 大尺寸拍照按钮，用于远程协助场景
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/vibration_util.dart';

/// 拍照按钮
/// 大尺寸圆形按钮，用于远程协助中拍照发送
class PhotoCaptureButton extends StatelessWidget {
  /// 点击回调
  final VoidCallback? onPressed;
  /// 是否正在拍照
  final bool isCapturing;
  /// 按钮文字
  final String label;

  const PhotoCaptureButton({
    super.key,
    this.onPressed,
    this.isCapturing = false,
    this.label = '拍照发送',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 大圆形拍照按钮
        GestureDetector(
          onTap: isCapturing
              ? null
              : () {
                  VibrationUtil.medium();
                  onPressed?.call();
                },
          child: AnimatedContainer(
            duration: AppDimensions.animNormal,
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: isCapturing
                  ? AppColors.textHint
                  : AppColors.assistOrange,
              shape: BoxShape.circle,
              boxShadow: isCapturing
                  ? []
                  : [
                      BoxShadow(
                        color: AppColors.assistOrange.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
              border: isCapturing
                  ? Border.all(color: AppColors.textHint, width: 4)
                  : Border.all(
                      color: AppColors.assistOrange.withOpacity(0.5),
                      width: 4,
                    ),
            ),
            child: isCapturing
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.textOnPrimary,
                      strokeWidth: 4,
                    ),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        size: 48,
                        color: AppColors.textOnPrimary,
                      ),
                      SizedBox(height: 4),
                      Text(
                        '拍照',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        // 按钮标签
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isCapturing ? AppColors.textHint : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
