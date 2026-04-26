/// 应用入口
/// 初始化服务、配置 Provider、启动应用
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/utils/storage_util.dart';
import 'core/network/dio_client.dart';
import 'core/network/sync_service.dart';
import 'core/utils/audio_player.dart';
import 'features/reminders/reminder_service.dart';
import 'shared/services/auth_service.dart';
import 'shared/services/task_service.dart';
import 'shared/services/emotion_service.dart';
import 'shared/services/communication_service.dart';
import 'shared/services/notification_service.dart';
import 'app.dart';

void main() async {
  // 确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化本地存储
  await StorageUtil.init();

  // 初始化网络客户端
  final dioClient = DioClient();

  // 初始化同步服务
  final syncService = SyncService(
    dioClient: dioClient,
    onStatusChanged: (status) {
      // 同步状态变化处理
      debugPrint('同步状态变化: $status');
    },
  );
  await syncService.init();

  // 初始化音频播放器
  await AudioPlayer().init();

  // 初始化提醒服务
  await ReminderService().init();

  // 初始化通知服务
  final notificationService = NotificationService(dioClient);
  await notificationService.init();

  // 运行应用
  runApp(
    /// Provider 多层嵌套，提供全局服务
    MultiProvider(
      providers: [
        // 网络客户端
        Provider<DioClient>.value(value: dioClient),
        // 同步服务
        Provider<SyncService>.value(value: syncService),
        // 认证服务
        Provider<AuthService>.value(
          value: AuthService(),
        ),
        // 任务服务
        ProxyProvider2<DioClient, SyncService, TaskService>(
          update: (_, dioClient, syncService, __) =>
              TaskService(dioClient, syncService: syncService),
        ),
        // 情绪服务
        ProxyProvider<DioClient, EmotionService>(
          update: (_, dioClient, __) => EmotionService(dioClient),
        ),
        // 沟通服务
        ProxyProvider<DioClient, CommunicationService>(
          update: (_, dioClient, __) => CommunicationService(dioClient),
        ),
        // 通知服务
        Provider<NotificationService>.value(value: notificationService),
      ],
      child: const WorkNavApp(),
    ),
  );
}
