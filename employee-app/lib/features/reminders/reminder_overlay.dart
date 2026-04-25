/// 提醒浮层
/// 全屏提醒浮层，用于重要任务提醒
library;

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/audio_player.dart';
import '../../core/utils/vibration_util.dart';

/// 提醒浮层
/// 以全屏浮层方式展示重要提醒，确保用户不会错过
class ReminderOverlay extends StatefulWidget {
  /// 提醒标题
  final String title;
  /// 提醒内容
  final String body;
  /// 提醒图标
  final IconData icon;
  /// 图标颜色
  final Color iconColor;
  /// 关闭回调
  final VoidCallback? onClose;
  /// 操作按钮文字和回调
  final String? actionText;
  final VoidCallback? onAction;

  const ReminderOverlay({
    super.key,
    required this.title,
    required this.body,
    this.icon = Icons.notifications_active,
    this.iconColor = AppColors.assistOrange,
    this.onClose,
    this.actionText,
    this.onAction,
  });

  /// 显示提醒浮层
  static void show(
    BuildContext context, {
    required String title,
    required String body,
    IconData icon = Icons.notifications_active,
    Color iconColor = AppColors.assistOrange,
    String? actionText,
    VoidCallback? onAction,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ReminderOverlay(
        title: title,
        body: body,
        icon: icon,
        iconColor: iconColor,
        actionText: actionText,
        onAction: onAction,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  State<ReminderOverlay> createState() => _ReminderOverlayState();
}

class _ReminderOverlayState extends State<ReminderOverlay>
    with SingleTickerProviderStateMixin {
  /// 脉冲动画
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // 脉冲动画（图标闪烁效果）
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    // 播放提醒语音和震动
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioPlayer().speak('${widget.title}。${widget.body}');
      VibrationUtil.warningPattern();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.iconColor.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 脉冲图标
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: widget.iconColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.icon,
                        size: 56,
                        color: widget.iconColor,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // 提醒标题
              Text(
                widget.title,
                style: AppTextStyles.headlineMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // 提醒内容
              Text(
                widget.body,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // 操作按钮
              if (widget.actionText != null) ...[
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: () {
                      VibrationUtil.medium();
                      widget.onAction?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.iconColor,
                      foregroundColor: AppColors.textOnPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      widget.actionText!,
                      style: AppTextStyles.buttonLarge.copyWith(
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // 关闭按钮
              SizedBox(
                width: 80,
                height: 80,
                child: ElevatedButton(
                  onPressed: () {
                    AudioPlayer().stop();
                    VibrationUtil.light();
                    widget.onClose?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: AppColors.textOnPrimary,
                    shape: const CircleBorder(),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 48,
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// AnimatedBuilder 简化版
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  }) : super();

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
