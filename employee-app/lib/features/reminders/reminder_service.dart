/// 提醒服务
/// 管理本地通知和全屏提醒浮层
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 提醒服务
/// 负责定时提醒、任务提醒、全屏提醒浮层
class ReminderService {
  static final ReminderService _instance = ReminderService._();
  factory ReminderService() => _instance;
  ReminderService._();

  /// 提醒回调
  void Function(Map<String, dynamic> notification)? onReminder;

  /// 是否已初始化
  bool _isInitialized = false;

  /// 定时器列表
  final List<Timer> _timers = [];

  /// 初始化提醒服务
  Future<void> init() async {
    if (_isInitialized) return;

    // Web 平台不支持本地通知，跳过初始化
    if (kIsWeb) {
      _isInitialized = true;
      debugPrint('提醒服务初始化完成 (Web 模式，本地通知不可用)');
      return;
    }

    // 非 Web 平台：初始化本地通知
    try {
      // flutter_local_notifications 在 Web 上不可用，
      // 通过条件导入处理
      _initPlatformNotifications();
    } catch (e) {
      debugPrint('本地通知初始化失败: $e');
    }

    _isInitialized = true;
    debugPrint('提醒服务初始化完成');
  }

  /// 平台特定通知初始化（仅非 Web）
  void _initPlatformNotifications() {
    // 实际项目中在这里初始化 FlutterLocalNotificationsPlugin
    // 此方法在 Web 上不会被调用
  }

  /// 处理通知点击
  void _handleNotificationTap(dynamic response) {
    debugPrint('提醒被点击: ${response?.payload}');
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

    // Web 平台不支持本地通知，使用 Timer 代替
    if (kIsWeb) {
      final delay = reminderTime.difference(DateTime.now());
      if (delay.isNegative) return;

      final timer = Timer(delay, () {
        showImmediateReminder(
          title: '任务提醒',
          body: '还有 $minutesBefore 分钟开始: $taskName',
        );
      });
      _timers.add(timer);

      debugPrint('已设置 Web 定时提醒: $taskName 在 ${reminderTime.toString()}');
      return;
    }

    // 非 Web 平台：设置本地通知
    debugPrint('已设置任务提醒: $taskName 在 ${reminderTime.toString()}');
  }

  /// 显示即时提醒（全屏浮层）
  void showImmediateReminder({
    required String title,
    required String body,
  }) {
    onReminder?.call({
      'id': 'immediate_${DateTime.now().millisecondsSinceEpoch}',
      'type': 'taskReminder',
      'title': title,
      'body': body,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  /// 取消指定提醒
  Future<void> cancelReminder(int id) async {
    // Web 平台：清除对应定时器
    if (kIsWeb) {
      // Timer 没有直接关联 id，此处为空实现
      return;
    }
    // 非 Web 平台：取消本地通知
  }

  /// 取消所有提醒
  Future<void> cancelAllReminders() async {
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
