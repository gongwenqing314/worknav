/// 情绪卡片组件
/// 展示单个情绪选项，大尺寸、高对比度
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../shared/models/emotion_record.dart';

/// 情绪卡片
/// 以大卡片形式展示情绪选项，点击选择当前情绪
class EmotionCard extends StatelessWidget {
  /// 情绪类型
  final EmotionType emotionType;
  /// 是否选中
  final bool isSelected;
  /// 点击回调
  final VoidCallback? onTap;

  const EmotionCard({
    super.key,
    required this.emotionType,
    this.isSelected = false,
    this.onTap,
  });

  /// 获取情绪名称
  String get _emotionName {
    final record = EmotionRecord(
      id: '',
      emotionType: emotionType,
      recordedAt: DateTime.now(),
    );
    return record.emotionName;
  }

  /// 获取 Emoji
  String get _emoji {
    final record = EmotionRecord(
      id: '',
      emotionType: emotionType,
      recordedAt: DateTime.now(),
    );
    return record.emoji;
  }

  /// 获取颜色
  Color get _color {
    final record = EmotionRecord(
      id: '',
      emotionType: emotionType,
      recordedAt: DateTime.now(),
    );
    return Color(record.colorValue);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDimensions.animNormal,
        width: double.infinity,
        height: AppDimensions.emotionCardHeight,
        padding: const EdgeInsets.all(AppDimensions.cardPadding),
        decoration: BoxDecoration(
          color: isSelected ? _color : _color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
          border: Border.all(
            color: isSelected ? _color : _color.withOpacity(0.3),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Emoji 图标
            Text(
              _emoji,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(width: 16),
            // 情绪名称
            Expanded(
              child: Text(
                _emotionName,
                style: AppTextStyles.headlineSmall.copyWith(
                  color: isSelected ? AppColors.textOnPrimary : _color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // 选中指示
            if (isSelected)
              const Icon(
                Icons.check_circle,
                size: 32,
                color: AppColors.textOnPrimary,
              ),
          ],
        ),
      ),
    );
  }
}
