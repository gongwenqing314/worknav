/// 通知服务
/// 管理本地通知和应用内通知
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/notification.dart' as model;

/// 通知服务
class NotificationService {
  final DioClient _dioClient;
  final FlutterLocalNotificationsPlugin _localNotifications;

  NotificationService(this._dioClient)
      : _localNotifications = FlutterLocalNotificationsPlugin();

  /// 初始化本地通知
  Future<void> init() async {
    // Android 通知初始化
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 通知初始化
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Android 请求通知权限
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// 通知点击回调
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('通知被点击: ${response.payload}');
    // TODO: 根据通知类型跳转到对应页面
  }

  /// 显示本地通知
  /// [id] 通知 ID
  /// [title] 通知标题
  /// [body] 通知内容
  /// [payload] 附加数据
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'worknav_employee',
      '工作导航通知',
      channelDescription: '任务提醒和重要通知',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// 显示任务提醒通知
  Future<void> showTaskReminder({
    required int id,
    required String taskName,
    required String scheduledTime,
  }) async {
    await showNotification(
      id: id,
      title: '任务提醒',
      body: '即将开始: $taskName ($scheduledTime)',
      payload: 'task_reminder',
    );
  }

  /// 显示情绪关注通知
  Future<void> showEmotionAlert({
    required int id,
    required String emotionName,
  }) async {
    await showNotification(
      id: id,
      title: '情绪关注',
      body: '员工表达了"$emotionName"的情绪，请关注',
      payload: 'emotion_alert',
    );
  }

  /// 取消指定通知
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// 取消所有通知
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// 获取应用内通知列表
  Future<List<model.AppNotification>> getNotifications() async {
    try {
      final response = await _dioClient.get(ApiConstants.notifications);
      final data = response.data;

      if (data != null && data['notifications'] != null) {
        return (data['notifications'] as List)
            .map((n) =>
                model.AppNotification.fromJson(n as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('获取通知列表失败: $e');
      return [];
    }
  }

  /// 标记通知已读
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _dioClient.post(
        ApiConstants.markNotificationRead
            .replaceAll('{id}', notificationId),
      );
      return true;
    } catch (e) {
      debugPrint('标记通知已读失败: $e');
      return false;
    }
  }
}
