/// MaterialApp 配置
/// 定义应用路由、主题、全局配置
library;

import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/splash_screen.dart';
import 'features/task/task_execution_screen.dart';
import 'shared/models/task_instance.dart';

/// 工作导航员工端应用
class WorkNavApp extends StatelessWidget {
  const WorkNavApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 应用标题
      title: '工作导航',
      debugShowCheckedModeBanner: false,

      // 应用主题（高对比度、大字体无障碍设计）
      theme: AppTheme.light,

      // 无暗色主题（心智障碍人士使用场景固定为浅色高对比度）
      darkTheme: null,

      // 启动页
      home: const SplashScreen(),

      // 路由配置
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/task/execution':
            // 任务执行页面
            final task = settings.arguments as TaskInstance?;
            if (task != null) {
              return MaterialPageRoute(
                builder: (_) => TaskExecutionScreen(task: task),
              );
            }
            return _errorRoute();
          default:
            return null;
        }
      },

      // 构建器：添加全局配置
      builder: (context, child) {
        // 确保文字缩放不会太小（无障碍保障）
        final mediaQuery = MediaQuery.of(context);
        final textScaleFactor = mediaQuery.textScaler.clamp(
          minScaleFactor: 1.0,
          maxScaleFactor: 1.5,
        );

        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: textScaleFactor),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }

  /// 错误路由
  MaterialPageRoute _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('页面不存在')),
        body: const Center(
          child: Text('抱歉，找不到这个页面。'),
        ),
      ),
    );
  }
}
