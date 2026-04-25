/// 全屏文字展示组件
/// 用于应急卡片等场景，全屏大字展示关键信息
library;

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/audio_player.dart';
import '../../core/utils/vibration_util.dart';

/// 全屏文字展示
/// 以全屏方式展示大字文字，用于应急沟通等场景
class FullScreenText extends StatefulWidget {
  /// 要展示的文字
  final String text;
  /// 背景色
  final Color? backgroundColor;
  /// 文字颜色
  final Color? textColor;
  /// 是否自动语音播报
  final bool autoSpeak;
  /// 关闭回调
  final VoidCallback? onClose;

  const FullScreenText({
    super.key,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.autoSpeak = true,
    this.onClose,
  });

  /// 显示全屏文字浮层
  static void show(
    BuildContext context, {
    required String text,
    Color? backgroundColor,
    Color? textColor,
    bool autoSpeak = true,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullScreenText(
          text: text,
          backgroundColor: backgroundColor,
          textColor: textColor,
          autoSpeak: autoSpeak,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  State<FullScreenText> createState() => _FullScreenTextState();
}

class _FullScreenTextState extends State<FullScreenText>
    with SingleTickerProviderStateMixin {
  /// 闪烁动画控制器
  late AnimationController _borderController;
  late Animation<double> _borderAnimation;

  /// 是否正在闪烁（视觉降级指示）
  bool _isFlashing = false;

  @override
  void initState() {
    super.initState();

    // 初始化边框闪烁动画
    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _borderAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _borderController, curve: Curves.easeInOut),
    );

    // 监听音频播放降级回调
    AudioPlayer().onVisualFallback = (text) {
      // TTS 不可用时，启动视觉降级（闪烁边框）
      if (mounted) {
        setState(() {
          _isFlashing = true;
        });
        _borderController.repeat(reverse: true);
      }
    };

    // 自动语音播报
    if (widget.autoSpeak) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AudioPlayer().speak(widget.text);
        VibrationUtil.medium();
      });
    }
  }

  @override
  void dispose() {
    _borderController.dispose();
    AudioPlayer().onVisualFallback = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ?? AppColors.surface;
    final txtColor = widget.textColor ?? AppColors.textPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _borderAnimation,
          builder: (context, child) {
            return Container(
              width: double.infinity,
              height: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: _isFlashing
                  ? BoxDecoration(
                      border: Border.all(
                        color: AppColors.primaryRed.withOpacity(
                          _borderAnimation.value,
                        ),
                        width: 8,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    )
                  : null,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 全屏大字文字
                  Text(
                    widget.text,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.fullScreenText.copyWith(
                      color: txtColor,
                      fontSize: 48,
                    ),
                  ),
                  const SizedBox(height: 48),
                  // 关闭按钮
                  SizedBox(
                    width: 120,
                    height: 120,
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
                        elevation: 4,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 56,
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '关闭',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// AnimatedBuilder 的简化别名
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  }) : super();

  Animation<double> get _animation => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
