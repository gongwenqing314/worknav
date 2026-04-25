/// 主页
/// 大图标卡片展示今日任务列表，底部导航切换功能页面
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import '../communication/communication_screen.dart';
import '../emotion/emotion_screen.dart';
import '../remote_assist/remote_assist_screen.dart';
import '../settings/settings_screen.dart';
import 'home_controller.dart';
import 'widgets/task_card.dart';
import 'widgets/greeting_bar.dart';
import '../../shared/widgets/loading_indicator.dart';

/// 主页
/// 展示今日任务列表，底部导航切换到沟通板、情绪、求助等功能
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// 页面控制器
  late PageController _pageController;
  late HomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HomeController();
    _pageController = PageController();

    // 加载任务数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadTasks();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// 底部导航切换
  void _onTabTapped(int index) {
    _controller.updateCurrentIndex(index);
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            _controller.updateCurrentIndex(index);
          },
          children: const [
            _TaskListPage(),
            CommunicationScreen(),
            EmotionScreen(),
            RemoteAssistScreen(),
            SettingsScreen(),
          ],
        ),
        // 底部导航栏
        bottomNavigationBar: Selector<HomeController, int>(
          selector: (_, controller) => controller.currentIndex,
          builder: (_, currentIndex, __) {
            return BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: _onTabTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: AppColors.surface,
              selectedItemColor: AppColors.primaryGreen,
              unselectedItemColor: AppColors.textHint,
              selectedLabelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.task_alt, size: 32),
                  activeIcon: Icon(Icons.task_alt, size: 36),
                  label: '任务',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble, size: 32),
                  activeIcon: Icon(Icons.chat_bubble, size: 36),
                  label: '沟通板',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.sentiment_satisfied, size: 32),
                  activeIcon: Icon(Icons.sentiment_satisfied, size: 36),
                  label: '情绪',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.support_agent, size: 32),
                  activeIcon: Icon(Icons.support_agent, size: 36),
                  label: '求助',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings, size: 32),
                  activeIcon: Icon(Icons.settings, size: 36),
                  label: '设置',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 任务列表页面
class _TaskListPage extends StatelessWidget {
  const _TaskListPage();

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, controller, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('今日任务'),
            actions: [
              // 同步状态指示
              if (controller.syncStatus == '离线')
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
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: controller.retry,
              color: AppColors.primaryGreen,
              child: _buildContent(context, controller),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, HomeController controller) {
    switch (controller.state) {
      case HomeState.loading:
        return const LoadingIndicator(message: '正在加载任务...');

      case HomeState.error:
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
                  onPressed: controller.retry,
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

      case HomeState.empty:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 80,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(height: 16),
              Text(
                '今天没有任务了',
                style: AppTextStyles.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '做得很好！好好休息吧。',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );

      case HomeState.ready:
        return CustomScrollView(
          slivers: [
            // 问候栏
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.pagePadding),
                child: GreetingBar(
                  employeeName: controller.employeeName,
                  syncStatus: controller.syncStatus,
                ),
              ),
            ),

            // 任务统计
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.pagePadding,
                ),
                child: Row(
                  children: [
                    _buildStatChip(
                      '待完成',
                      '${controller.pendingCount}',
                      AppColors.taskPending,
                    ),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      '进行中',
                      '${controller.inProgressCount}',
                      AppColors.taskInProgress,
                    ),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      '已完成',
                      '${controller.completedCount}',
                      AppColors.taskCompleted,
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // 任务列表
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final task = controller.tasks[index];
                  return TaskCard(
                    task: task,
                    onTap: () {
                      // 跳转到任务执行页面
                      Navigator.of(context).pushNamed(
                        '/task/execution',
                        arguments: task,
                      );
                    },
                  );
                },
                childCount: controller.tasks.length,
              ),
            ),

            // 底部间距
            const SliverToBoxAdapter(
              child: SizedBox(height: AppDimensions.bottomNavHeight + 16),
            ),
          ],
        );
    }
  }

  /// 统计标签
  Widget _buildStatChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
