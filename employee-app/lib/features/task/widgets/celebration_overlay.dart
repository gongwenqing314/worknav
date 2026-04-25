/// 完成庆祝动画浮层
/// 任务完成时展示的庆祝效果
library;

import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/audio_player.dart';
import '../../../core/utils/vibration_util.dart';

/// 完成庆祝动画浮层
/// 当所有步骤完成时，展示庆祝动画和鼓励文字
class CelebrationOverlay extends StatefulWidget {
  /// 任务名称
  final String taskName;
  /// 关闭回调
  final VoidCallback? onClose;

  const CelebrationOverlay({
    super.key,
    required this.taskName,
    this.onClose,
  });

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with TickerProviderStateMixin {
  /// 缩放动画控制器
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  /// 透明度动画控制器
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  /// 粒子列表
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // 缩放动画（图标弹出效果）
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.elasticOut,
      ),
    );

    // 透明度动画（整体淡入）
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // 启动动画
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _scaleController.forward();
    });

    // 生成庆祝粒子
    _generateParticles();

    // 播放庆祝语音和震动
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioPlayer().speak('太棒了！你完成了${widget.taskName}！');
      VibrationUtil.successPattern();
    });
  }

  /// 生成庆祝粒子
  void _generateParticles() {
    final colors = [
      AppColors.primaryGreen,
      AppColors.primaryBlue,
      AppColors.assistOrange,
      AppColors.emotionPurple,
      AppColors.taskPending,
    ];

    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        color: colors[_random.nextInt(colors.length)],
        size: _random.nextDouble() * 16 + 8,
        speedY: _random.nextDouble() * 0.005 + 0.002,
        speedX: (Random().nextDouble() - 0.5) * 0.003,
      ));
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 庆祝图标（带缩放动画）
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen,
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.celebration,
                    size: 80,
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 祝贺文字
              Text(
                '太棒了！',
                style: AppTextStyles.headlineLarge.copyWith(
                  color: AppColors.textOnPrimary,
                  fontSize: 36,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '你完成了"${widget.taskName}"',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textOnPrimary.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 48),

              // 继续按钮
              SizedBox(
                width: 200,
                height: 64,
                child: ElevatedButton(
                  onPressed: () {
                    VibrationUtil.light();
                    widget.onClose?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: AppColors.textOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    '继续',
                    style: AppTextStyles.buttonLarge.copyWith(fontSize: 24),
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

/// 庆祝粒子
class _Particle {
  final double x;
  final double y;
  final Color color;
  final double size;
  final double speedY;
  final double speedX;

  _Particle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.speedY,
    required this.speedX,
  });
}
