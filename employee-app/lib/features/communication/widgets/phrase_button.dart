/// 常用语大按钮组件
/// 沟通板中的核心交互组件
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/vibration_util.dart';
import '../../../shared/models/comm_phrase.dart';

/// 常用语大按钮
/// 点击后播放语音并展示文字
class PhraseButton extends StatelessWidget {
  /// 常用语数据
  final CommPhrase phrase;
  /// 点击回调
  final VoidCallback? onTap;

  const PhraseButton({
    super.key,
    required this.phrase,
    this.onTap,
  });

  /// 获取图标
  IconData get _icon {
    switch (phrase.iconName) {
      case 'help':
        return Icons.help_outline;
      case 'check_circle':
        return Icons.check_circle_outline;
      case 'question_mark':
        return Icons.help_outline;
      case 'pause_circle':
        return Icons.pause_circle_outline;
      case 'coffee':
        return Icons.free_breakfast_outlined;
      case 'thumb_up':
        return Icons.thumb_up_outlined;
      case 'favorite':
        return Icons.favorite_outline;
      case 'sick':
        return Icons.sick_outlined;
      default:
        return Icons.chat_bubble_outline;
    }
  }

  /// 获取按钮颜色
  Color get _buttonColor {
    switch (phrase.category) {
      case 'help':
        return AppColors.primaryRed;
      case 'status':
        return AppColors.primaryGreen;
      case 'general':
      default:
        return AppColors.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.phraseButtonHeight,
      child: ElevatedButton(
        onPressed: () {
          VibrationUtil.medium();
          onTap?.call();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _buttonColor,
          foregroundColor: AppColors.textOnPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
          ),
          elevation: 4,
          shadowColor: _buttonColor.withOpacity(0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 图标
            Icon(
              _icon,
              size: 40,
              color: AppColors.textOnPrimary,
            ),
            const SizedBox(width: 12),
            // 文字
            Expanded(
              child: Text(
                phrase.text,
                style: AppTextStyles.buttonLarge.copyWith(
                  fontSize: 22,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
