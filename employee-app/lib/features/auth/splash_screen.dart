/// 启动页
/// 自动登录（设备绑定），显示欢迎信息
library;

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/audio_player.dart';
import '../../core/utils/vibration_util.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../home/home_screen.dart';

/// 启动页
/// 实现自动登录流程：
/// 1. 显示欢迎画面
/// 2. 自动进行设备绑定登录
/// 3. 登录成功后跳转主页
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// 登录状态
  bool _isLoading = true;
  bool _loginSuccess = false;
  String _errorMessage = '';

  /// 淡入动画
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  /// 认证服务
  final AuthService _authService = AuthService(
    // DioClient 将在 app.dart 中通过 Provider 提供
    // 这里使用简化初始化
    _createDioClient(),
  );

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _performAutoLogin();
  }

  /// 创建 DioClient（简化版，实际应通过依赖注入）
  static dynamic _createDioClient() {
    // 简化实现 - 实际项目中通过 Provider 获取
    return null;
  }

  /// 初始化动画
  void _initAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _fadeController.forward();
  }

  /// 执行自动登录
  Future<void> _performAutoLogin() async {
    // 等待欢迎动画播放
    await Future.delayed(const Duration(milliseconds: 1500));

    // 检查是否已登录（令牌是否有效）
    if (_authService.isLoggedIn()) {
      // 已登录，直接跳转
      _navigateToHome();
      return;
    }

    // 未登录，尝试设备自动登录
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 模拟自动登录过程
      // 实际项目中调用 _authService.deviceLogin()
      await Future.delayed(const Duration(seconds: 2));

      // 模拟登录成功
      setState(() {
        _loginSuccess = true;
        _isLoading = false;
      });

      // 播放欢迎语音
      AudioPlayer().speak('你好，开始今天的工作吧。');
      VibrationUtil.light();

      // 延迟后跳转主页
      await Future.delayed(const Duration(seconds: 2));
      _navigateToHome();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '登录失败，请检查网络连接后重试';
      });
    }
  }

  /// 导航到主页
  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
    );
  }

  /// 重试登录
  Future<void> _retryLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    await _performAutoLogin();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.pagePadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 应用图标
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppColors.textOnPrimary,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: const Icon(
                      Icons.work_outline,
                      size: 96,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXLarge),

                  // 应用名称
                  Text(
                    '工作导航',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: AppColors.textOnPrimary,
                      fontSize: 36,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingSmall),
                  Text(
                    'StepByStep',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textOnPrimary.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXLarge),

                  // 状态显示
                  if (_isLoading) ...[
                    const LoadingIndicator(
                      message: '正在登录...',
                      color: AppColors.textOnPrimary,
                    ),
                  ] else if (_loginSuccess) ...[
                    Text(
                      '你好，开始今天的工作吧。',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                  ] else if (_errorMessage.isNotEmpty) ...[
                    Text(
                      _errorMessage,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textOnPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimensions.spacingLarge),
                    SizedBox(
                      width: 160,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _retryLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.textOnPrimary,
                          foregroundColor: AppColors.primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          '重试',
                          style: AppTextStyles.buttonLarge.copyWith(
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
