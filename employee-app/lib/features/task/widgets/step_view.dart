/// 步骤展示组件
/// 大图片+文字展示当前步骤内容
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../shared/models/task_template.dart';

/// 步骤展示组件
/// 以大图片和文字展示当前步骤的详细内容
class StepView extends StatelessWidget {
  /// 步骤数据
  final TaskStep step;
  /// 步骤序号（从1开始）
  final int stepNumber;
  /// 步骤总数
  final int totalSteps;
  /// 是否为已完成步骤（回看模式）
  final bool isCompleted;
  /// 图片加载失败时的占位文字
  final String placeholderText;

  const StepView({
    super.key,
    required this.step,
    required this.stepNumber,
    required this.totalSteps,
    this.isCompleted = false,
    this.placeholderText = '步骤图片',
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 步骤编号指示
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.primaryGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '已完成',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '第 $stepNumber 步 / 共 $totalSteps 步',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacingLarge),

          // 步骤图片（大图展示）
          _buildStepImage(),

          const SizedBox(height: AppDimensions.spacingLarge),

          // 步骤标题
          Text(
            step.title,
            style: AppTextStyles.headlineMedium,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppDimensions.spacingMedium),

          // 步骤说明文字
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.cardPadding),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusMedium),
              border: Border.all(
                color: AppColors.divider,
                width: 1,
              ),
            ),
            child: Text(
              step.instruction,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary,
                height: 1.6,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建步骤图片
  Widget _buildStepImage() {
    // 如果有图片 URL，显示网络图片
    if (step.imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadiusMedium),
        child: Container(
          width: double.infinity,
          height: 280,
          color: AppColors.surfaceVariant,
          child: Image.network(
            step.imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholder();
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryBlue,
                ),
              );
            },
          ),
        ),
      );
    }

    // 无图片时显示占位
    return _buildPlaceholder();
  }

  /// 构建占位图
  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadiusMedium),
        border: Border.all(
          color: AppColors.divider,
          width: 2,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image,
            size: 80,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 8),
          Text(
            placeholderText,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}
