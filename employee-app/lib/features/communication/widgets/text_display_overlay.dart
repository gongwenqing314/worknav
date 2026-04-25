/// 文字展示浮层
/// 点击常用语后全屏展示文字，辅助沟通
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/audio_player.dart';
import '../../../core/utils/vibration_util.dart';

/// 文字展示浮层
/// 点击常用语后弹出，以大字展示文字内容，辅助沟通
class TextDisplayOverlay extends StatefulWidget {
  /// 要展示的文字
  final String text;
  /// 背景色
  final Color? backgroundColor;

  const TextDisplayOverlay({
    super.key,
    required this.text,
    this.backgroundColor,
  });

  /// 显示文字浮层
  static void show(BuildContext context, {required String text}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => TextDisplayOverlay(text: text),
    );
  }

  @override
  State<TextDisplayOverlay> createState() => _TextDisplayOverlayState();
}

class _TextDisplayOverlayState extends State<TextDisplayOverlay>
    with SingleTickerProviderStateMixin {
  /// 缩放动画
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  /// 是否正在闪烁（视觉降级指示）
  bool _isFlashing = false;
  late AnimationController _flashController;
  late Animation<double> _flashAnimation;

  @override
  void initState() {
    super.initState();

    // 缩放弹出动画
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );
    _scaleController.forward();

    // 闪烁动画（视觉降级时使用）
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flashAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeInOut),
    );

    // 播放语音
    AudioPlayer().speak(widget.text);
    VibrationUtil.medium();

    // 监听视觉降级
    AudioPlayer().onVisualFallback = (text) {
      if (mounted) {
        setState(() => _isFlashing = true);
        _flashController.repeat(reverse: true);
      }
    };
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _flashController.dispose();
    AudioPlayer().onVisualFallback = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ?? AppColors.surface;

    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: _isFlashing
                ? Border.all(
                    color: AppColors.primaryRed.withOpacity(
                      _flashAnimation.value,
                    ),
                    width: 4,
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 大字文字
              Text(
                widget.text,
                style: AppTextStyles.fullScreenText.copyWith(
                  fontSize: 40,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // 关闭按钮
              SizedBox(
                width: 80,
                height: 80,
                child: ElevatedButton(
                  onPressed: () {
                    AudioPlayer().stop();
                    VibrationUtil.light();
                    Navigator.of(context).pop();
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
