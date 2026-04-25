/// 提醒服务
/// 管理本地通知和全屏提醒浮层
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../shared/models/notification.dart' as model;

/// 提醒服务
/// 负责定时提醒、任务提醒、全屏提醒浮层
class ReminderService {
  static final ReminderService _instance = ReminderService._();
  factory ReminderService() => _instance;
  ReminderService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// 提醒回调
  final void Function(model.AppNotification notification)? onReminder;

  /// 是否已初始化
  bool _isInitialized = false;

  /// 定时器列表
  final List<Timer> _timers = [];

  /// 初始化提醒服务
  Future<void> init() async {
    if (_isInitialized) return;

    // 初始化本地通知
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    _isInitialized = true;
    debugPrint('提醒服务初始化完成');
  }

  /// 处理通知点击
  void _handleNotificationTap(NotificationResponse response) {
    debugPrint('提醒被点击: ${response.payload}');
    // TODO: 根据通知类型跳转到对应页面
  }

  /// 设置任务提醒
  /// [id] 提醒 ID
  /// [taskName] 任务名称
  /// [scheduledTime] 计划时间
  /// [minutesBefore] 提前多少分钟提醒
  Future<void> setTaskReminder({
    required int id,
    required String taskName,
    required DateTime scheduledTime,
    int minutesBefore = 5,
  }) async {
    if (!_isInitialized) await init();

    // 计算提醒时间
    final reminderTime = scheduledTime.subtract(
      Duration(minutes: minutesBefore),
    );

    // 如果提醒时间已过，不设置
    if (reminderTime.isBefore(DateTime.now())) {
      debugPrint('提醒时间已过，跳过: $taskName');
      return;
    }

    // 设置本地通知
    const androidDetails = AndroidNotificationDetails(
      'task_reminders',
      '任务提醒',
      channelDescription: '任务开始前的提醒通知',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _notifications.schedule(
      id,
      '任务提醒',
      '还有 $minutesBefore 分钟开始: $taskName',
      reminderTime,
      const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );

    debugPrint('已设置任务提醒: $taskName 在 ${reminderTime.toString()}');
  }

  /// 显示即时提醒（全屏浮层）
  void showImmediateReminder({
    required String title,
    required String body,
  }) {
    onReminder?.call(model.AppNotification(
      id: 'immediate_${DateTime.now().millisecondsSinceEpoch}',
      type: model.NotificationType.taskReminder,
      title: title,
      body: body,
      createdAt: DateTime.now(),
    ));
  }

  /// 取消指定提醒
  Future<void> cancelReminder(int id) async {
    await _notifications.cancel(id);
  }

  /// 取消所有提醒
  Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
    // 取消所有定时器
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
  }

  /// 释放资源
  void dispose() {
    cancelAllReminders();
  }
}
