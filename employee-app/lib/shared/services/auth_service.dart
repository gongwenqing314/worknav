/// 认证服务
/// 处理设备绑定登录、令牌管理等
library;

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/storage_util.dart';

/// 认证服务
class AuthService {
  /// 设备自动登录
  Future<bool> deviceLogin() async {
    try {
      // 获取设备 ID
      String? deviceId = StorageUtil.getString(StorageUtil.keyDeviceId);
      if (deviceId == null || deviceId.isEmpty) {
        deviceId = await _getDeviceId();
        await StorageUtil.setString(StorageUtil.keyDeviceId, deviceId);
      }

      debugPrint('设备登录: 使用设备ID = $deviceId');

      // 使用 dart:html HttpRequest 直接发送请求（绕过 Dio Web 兼容性问题）
      final response = await _httpPost(
        '${ApiConstants.baseUrl}${ApiConstants.deviceLogin}',
        {
          'deviceId': deviceId,
          'platform': _getPlatformName(),
          'appVersion': '1.0.0',
        },
      );

      debugPrint('设备登录: 响应 code = ${response['code']}');

      if (response['code'] == 200) {
        final inner = response['data'];
        if (inner != null && inner is Map<String, dynamic>) {
          final token = inner['accessToken'] as String?;
          final refreshToken = inner['refreshToken'] as String?;
          final employeeId = inner['employeeId']?.toString();
          final employeeName = inner['employeeName'] as String?;

          if (token != null) {
            await StorageUtil.setString(StorageUtil.keyAuthToken, token);
            if (refreshToken != null) {
              await StorageUtil.setString(
                  StorageUtil.keyRefreshToken, refreshToken);
            }
            if (employeeId != null) {
              await StorageUtil.setString(StorageUtil.keyEmployeeId, employeeId);
            }
            if (employeeName != null) {
              await StorageUtil.setString(
                  StorageUtil.keyEmployeeName, employeeName);
            }
            await StorageUtil.setBool(StorageUtil.keyIsLoggedIn, true);
            debugPrint('设备登录: 成功, 员工=$employeeName');
            return true;
          }
        }
      }

      debugPrint('设备登录: 登录失败');
      return false;
    } catch (e, stack) {
      debugPrint('设备登录失败: $e');
      debugPrint('堆栈: $stack');
      return false;
    }
  }

  /// 检查是否已登录
  bool isLoggedIn() {
    return StorageUtil.getBool(StorageUtil.keyIsLoggedIn, defaultValue: false) ??
        false;
  }

  /// 获取当前员工姓名
  String? getEmployeeName() {
    return StorageUtil.getString(StorageUtil.keyEmployeeName);
  }

  /// 获取当前员工 ID
  String? getEmployeeId() {
    return StorageUtil.getString(StorageUtil.keyEmployeeId);
  }

  /// 登出
  Future<void> logout() async {
    try {
      await _httpPost('${ApiConstants.baseUrl}${ApiConstants.logout}', {});
    } catch (_) {}

    await StorageUtil.remove(StorageUtil.keyAuthToken);
    await StorageUtil.remove(StorageUtil.keyRefreshToken);
    await StorageUtil.setBool(StorageUtil.keyIsLoggedIn, false);
  }

  /// 获取设备唯一标识
  Future<String> _getDeviceId() async {
    if (kIsWeb) {
      final existing = StorageUtil.getString(StorageUtil.keyDeviceId);
      if (existing != null && existing.isNotEmpty) return existing;
      return 'web_device_xiaoming';
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return 'device_${timestamp}_$random';
  }

  /// 获取平台名称（兼容 Web）
  String _getPlatformName() {
    if (kIsWeb) return 'web';
    return 'unknown';
  }

  /// HTTP POST 请求（使用 dart:html）
  Future<Map<String, dynamic>> _httpPost(String url, Map<String, dynamic> data) async {
    final completer = Completer<Map<String, dynamic>>();
    final request = html.HttpRequest();

    request.open('POST', url, async: true);
    request.setRequestHeader('Content-Type', 'application/json');
    request.setRequestHeader('Accept', 'application/json');

    request.onLoad.first.then((_) {
      try {
        if (request.status == 200 || request.status == 201) {
          final body = request.responseText;
          if (body != null && body.isNotEmpty) {
            completer.complete(jsonDecode(body) as Map<String, dynamic>);
          } else {
            completer.complete({'code': 200, 'data': null});
          }
        } else {
          debugPrint('HTTP POST $url 返回 ${request.status}');
          completer.complete({'code': request.status, 'message': '请求失败', 'data': null});
        }
      } catch (e) {
        completer.completeError(e);
      }
    });

    request.onError.first.then((_) {
      completer.completeError(Exception('网络请求失败'));
    });

    request.send(jsonEncode(data));
    return completer.future;
  }
}
