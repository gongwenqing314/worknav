/// 步骤进度条组件
/// 显示任务步骤的整体完成进度
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';

/// 步骤进度条
/// 以圆点+连线的方式展示各步骤的完成状态
class StepProgressBar extends StatelessWidget {
  /// 步骤总数
  final int totalSteps;
  /// 当前步骤索引（从0开始）
  final int currentStepIndex;
  /// 已完成的步骤索引集合
  final Set<int> completedSteps;

  const StepProgressBar({
    super.key,
    required this.totalSteps,
    required this.currentStepIndex,
    this.completedSteps = const {},
  });

  @override
  Widget build(BuildContext context) {
    if (totalSteps <= 1) {
      // 只有一个步骤时不显示进度条
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pagePadding,
        vertical: AppDimensions.spacingMedium,
      ),
      child: Row(
        children: List.generate(totalSteps, (index) {
          return Expanded(
            child: _buildStepIndicator(index),
          );
        }),
      ),
    );
  }

  /// 构建单个步骤指示器
  Widget _buildStepIndicator(int index) {
    final isCompleted = completedSteps.contains(index);
    final isCurrent = index == currentStepIndex;
    final isPast = index < currentStepIndex;

    // 确定颜色
    Color color;
    if (isCompleted) {
      color = AppColors.primaryGreen;
    } else if (isCurrent) {
      color = AppColors.primaryBlue;
    } else {
      color = AppColors.divider;
    }

    return Row(
      children: [
        // 步骤圆点
        Expanded(
          child: Column(
            children: [
              // 圆点
              AnimatedContainer(
                duration: AppDimensions.animNormal,
                width: isCurrent ? 28 : 20,
                height: isCurrent ? 28 : 20,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isCurrent
                      ? Border.all(
                          color: color,
                          width: 3,
                        )
                      : null,
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: isCompleted
                    ? const Icon(
                        Icons.check,
                        size: 14,
                        color: AppColors.textOnPrimary,
                      )
                    : null,
              ),
              const SizedBox(height: 4),
              // 步骤编号
              Text(
                '${index + 1}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: color,
                  fontSize: 14,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),

        // 连接线（最后一个步骤不需要）
        if (index < totalSteps - 1)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: isPast ? AppColors.primaryGreen : AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
