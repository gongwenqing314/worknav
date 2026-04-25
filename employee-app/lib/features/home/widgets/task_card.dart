/// 任务卡片组件
/// 大图标卡片展示单个任务，高对比度、大字体
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/vibration_util.dart';
import '../../../shared/models/task_instance.dart';

/// 任务卡片
/// 以大图标卡片形式展示任务信息，支持点击进入任务执行
class TaskCard extends StatelessWidget {
  /// 任务实例
  final TaskInstance task;
  /// 点击回调
  final VoidCallback? onTap;
  /// 请求帮助回调
  final VoidCallback? onHelp;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onHelp,
  });

  /// 根据任务状态获取背景色
  Color _getStatusColor() {
    switch (task.status) {
      case TaskStatus.pending:
        return AppColors.taskPending;
      case TaskStatus.inProgress:
        return AppColors.taskInProgress;
      case TaskStatus.completed:
        return AppColors.taskCompleted;
      case TaskStatus.needHelp:
        return AppColors.taskNeedHelp;
      case TaskStatus.skipped:
        return AppColors.textHint;
    }
  }

  /// 根据任务状态获取状态文字
  String _getStatusText() {
    switch (task.status) {
      case TaskStatus.pending:
        return '待开始';
      case TaskStatus.inProgress:
        return '进行中';
      case TaskStatus.completed:
        return '已完成';
      case TaskStatus.needHelp:
        return '需要帮助';
      case TaskStatus.skipped:
        return '已跳过';
    }
  }

  /// 根据任务状态获取图标
  IconData _getStatusIcon() {
    switch (task.status) {
      case TaskStatus.pending:
        return Icons.schedule;
      case TaskStatus.inProgress:
        return Icons.play_circle;
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.needHelp:
        return Icons.help;
      case TaskStatus.skipped:
        return Icons.skip_next;
    }
  }

  /// 获取计划时间显示
  String _getScheduledTime() {
    final hour = task.scheduledTime.hour;
    final minute = task.scheduledTime.minute;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pagePadding,
        vertical: AppDimensions.spacingSmall,
      ),
      child: InkWell(
        onTap: () {
          VibrationUtil.light();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.cardPadding),
          child: Row(
            children: [
              // 任务图标（大图标 >= 120x120dp）
              Container(
                width: AppDimensions.taskCardIconSize,
                height: AppDimensions.taskCardIconSize,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.borderRadiusMedium,
                  ),
                ),
                child: Icon(
                  _getStatusIcon(),
                  size: 64,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMedium),

              // 任务信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 任务名称
                    Text(
                      task.name,
                      style: AppTextStyles.headlineSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // 任务描述
                    Text(
                      task.description,
                      style: AppTextStyles.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimensions.spacingSmall),

                    // 进度条
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: task.progress,
                              backgroundColor: AppColors.divider,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                statusColor,
                              ),
                              minHeight: AppDimensions.progressBarHeight,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${task.completedSteps}/${task.totalSteps}',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppDimensions.spacingSmall),

              // 右侧操作区
              Column(
                children: [
                  // 计划时间
                  Text(
                    _getScheduledTime(),
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 状态标签
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
