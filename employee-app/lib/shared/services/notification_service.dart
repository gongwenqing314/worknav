/// 通知服务
/// 管理本地通知和应用内通知
library;

import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/storage_util.dart';
import '../models/notification.dart' as model;

/// 通知服务
class NotificationService {
  final DioClient _dioClient;

  NotificationService(this._dioClient);

  /// 初始化本地通知（Web 平台跳过）
  Future<void> init() async {
    if (kIsWeb) {
      debugPrint('通知服务: Web 模式，本地通知不可用');
      return;
    }
    // 非 Web 平台的本地通知初始化
    // 实际设备上通过 conditional import 初始化 flutter_local_notifications
    debugPrint('通知服务: 已初始化');
  }

  /// 显示本地通知
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;
    debugPrint('显示通知: $title - $body');
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
    if (kIsWeb) return;
  }

  /// 取消所有通知
  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
  }

  /// Web 平台 HTTP GET 请求辅助方法
  Future<Map<String, dynamic>?> _webGet(String path) async {
    final url = '${ApiConstants.baseUrl}$path';
    final rawToken = html.window.localStorage['flutter.auth_token'];
    String? token;
    if (rawToken != null && rawToken.isNotEmpty) {
      try { token = (jsonDecode(rawToken) as String); } catch (_) { token = rawToken; }
    }
    final request = html.HttpRequest();
    request.open('GET', url, async: true);
    request.setRequestHeader('Content-Type', 'application/json');
    request.setRequestHeader('Accept', 'application/json');
    if (token != null && token.isNotEmpty) {
      request.setRequestHeader('Authorization', 'Bearer $token');
    }
    request.send();
    await request.onLoad.first;
    if (request.status == 200) {
      return jsonDecode(request.responseText!) as Map<String, dynamic>;
    }
    throw Exception('Web request failed: ${request.status} ${request.statusText}');
  }

  /// Web 平台 HTTP PUT 请求辅助方法
  Future<Map<String, dynamic>?> _webPut(String path, {dynamic data}) async {
    final url = '${ApiConstants.baseUrl}$path';
    final rawToken = html.window.localStorage['flutter.auth_token'];
    String? token;
    if (rawToken != null && rawToken.isNotEmpty) {
      try { token = (jsonDecode(rawToken) as String); } catch (_) { token = rawToken; }
    }
    final request = html.HttpRequest();
    request.open('PUT', url, async: true);
    request.setRequestHeader('Content-Type', 'application/json');
    request.setRequestHeader('Accept', 'application/json');
    if (token != null && token.isNotEmpty) {
      request.setRequestHeader('Authorization', 'Bearer $token');
    }
    request.send(jsonEncode(data));
    await request.onLoad.first;
    if (request.status == 200) {
      if (request.responseText != null && request.responseText!.isNotEmpty) {
        return jsonDecode(request.responseText!) as Map<String, dynamic>;
      }
      return {};
    }
    throw Exception('Web request failed: ${request.status} ${request.statusText}');
  }

  /// 获取应用内通知列表
  Future<List<model.AppNotification>> getNotifications() async {
    try {
      Map<String, dynamic>? data;
      if (kIsWeb) {
        data = await _webGet(ApiConstants.notifications);
      } else {
        final response = await _dioClient.get(ApiConstants.notifications);
        data = response.data;
      }

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
      if (kIsWeb) {
        await _webPut('/notifications/$notificationId/read');
      } else {
        await _dioClient.put(
          '/notifications/$notificationId/read',
        );
      }
      return true;
    } catch (e) {
      debugPrint('标记通知已读失败: $e');
      return false;
    }
  }
}
