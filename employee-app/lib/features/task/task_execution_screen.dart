/// 任务执行页面
/// 逐步引导员工完成任务，大图片+文字，语音提示+震动
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/audio_player.dart';
import '../../../core/utils/vibration_util.dart';
import '../../../shared/models/task_instance.dart';
import '../../../shared/widgets/loading_indicator.dart';
import 'task_execution_controller.dart';
import 'widgets/step_view.dart';
import 'widgets/step_progress_bar.dart';
import 'widgets/complete_button.dart';
import 'widgets/back_step_button.dart';
import 'widgets/help_button.dart';
import 'widgets/celebration_overlay.dart';

/// 任务执行页面
/// 核心功能页面：逐步引导员工完成工作任务的每个步骤
class TaskExecutionScreen extends StatefulWidget {
  /// 任务实例
  final TaskInstance task;

  const TaskExecutionScreen({
    super.key,
    required this.task,
  });

  @override
  State<TaskExecutionScreen> createState() => _TaskExecutionScreenState();
}

class _TaskExecutionScreenState extends State<TaskExecutionScreen> {
  late TaskExecutionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TaskExecutionController(task: widget.task);
    // 加载任务详情
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadTaskDetail();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 步骤变化时播放语音提示
  void _onStepChanged() {
    final step = _controller.currentStep;
    if (step != null) {
      // 播放步骤说明语音
      AudioPlayer().speak(step.instruction, audioPath: step.audioAsset);
      // 震动反馈
      VibrationUtil.light();
    }
  }

  /// 完成当前步骤
  void _onCompleteStep() {
    _controller.completeCurrentStep();

    // 如果任务全部完成，播放庆祝语音
    if (_controller.showCelebration) {
      // 庆祝动画内部会播放语音
    } else {
      // 播放新步骤语音
      Future.delayed(const Duration(milliseconds: 300), () {
        _onStepChanged();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(widget.task.name),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, size: 32),
            onPressed: () {
              VibrationUtil.light();
              Navigator.of(context).pop();
            },
          ),
          actions: [
            // 离线指示器
            if (widget.task.isOffline)
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(
                  Icons.wifi_off,
                  color: AppColors.primaryRed,
                  size: 28,
                ),
              ),
          ],
        ),
        body: Consumer<TaskExecutionController>(
          builder: (context, controller, _) {
            return Stack(
              children: [
                // 主内容区
                _buildBody(controller),

                // 庆祝动画浮层
                if (controller.showCelebration)
                  CelebrationOverlay(
                    taskName: widget.task.name,
                    onClose: () {
                      Navigator.of(context).pop(true);
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 构建页面主体
  Widget _buildBody(TaskExecutionController controller) {
    switch (controller.state) {
      case TaskExecutionState.loading:
        return const LoadingIndicator(message: '正在加载任务...');

      case TaskExecutionState.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.primaryRed,
              ),
              const SizedBox(height: 16),
              Text(
                controller.errorMessage,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 160,
                height: 56,
                child: ElevatedButton(
                  onPressed: controller.loadTaskDetail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: AppColors.textOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    '重试',
                    style: AppTextStyles.buttonLarge,
                  ),
                ),
              ),
            ],
          ),
        );

      case TaskExecutionState.executing:
      case TaskExecutionState.needHelp:
        return _buildExecutionContent(controller);

      case TaskExecutionState.completed:
        // 庆祝动画覆盖整个页面
        return const SizedBox.shrink();
    }
  }

  /// 构建任务执行内容
  Widget _buildExecutionContent(TaskExecutionController controller) {
    final step = controller.currentStep;

    if (step == null) {
      return const Center(
        child: Text('步骤数据异常', style: AppTextStyles.bodyLarge),
      );
    }

    return Column(
      children: [
        // 步骤进度条
        StepProgressBar(
          totalSteps: controller.totalSteps,
          currentStepIndex: controller.currentStepIndex,
          completedSteps: controller.completedSteps,
        ),

        // 步骤内容展示（可滚动区域）
        Expanded(
          child: StepView(
            step: step,
            stepNumber: controller.currentStepIndex + 1,
            totalSteps: controller.totalSteps,
            isCompleted: controller.isCurrentStepCompleted,
          ),
        ),

        // 操作按钮区域
        SafeArea(
          child: Column(
            children: [
              // 返回上一步按钮
              BackStepButton(
                canGoBack: !controller.isFirstStep,
                onPressed: () {
                  controller.goToPreviousStep();
                  _onStepChanged();
                },
              ),

              const SizedBox(height: AppDimensions.spacingSmall),

              // 完成当前步骤按钮（已完成步骤回看时显示"继续"）
              CompleteButton(
                isEnabled: true,
                text: controller.isCurrentStepCompleted ? '继续下一步' : '完成了',
                onPressed: _onCompleteStep,
              ),

              const SizedBox(height: AppDimensions.spacingSmall),

              // 求助按钮
              HelpButton(
                isRequesting: controller.isRequestingHelp,
                onPressed: () {
                  _showHelpConfirmDialog(context);
                },
              ),

              const SizedBox(height: AppDimensions.spacingSmall),
            ],
          ),
        ),
      ],
    );
  }

  /// 显示求助确认对话框
  void _showHelpConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            '需要帮助吗？',
            style: AppTextStyles.headlineSmall,
          ),
          content: Text(
            '我们会通知管理员来帮助你。确定要发送求助请求吗？',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                '取消',
                style: AppTextStyles.buttonMedium,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _controller.requestHelp();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: AppColors.textOnPrimary,
              ),
              child: Text(
                '发送求助',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: AppColors.textOnPrimary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
