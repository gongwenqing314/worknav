/// 认证服务
/// 处理设备绑定登录、令牌管理等
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/storage_util.dart';

/// 认证服务
class AuthService {
  final DioClient _dioClient;

  AuthService(this._dioClient);

  /// 设备自动登录
  /// 使用设备唯一标识进行绑定登录，无需手动输入账号密码
  Future<bool> deviceLogin() async {
    try {
      // 获取设备 ID（已存储则复用，否则生成新的）
      String? deviceId = StorageUtil.getString(StorageUtil.keyDeviceId);
      if (deviceId == null || deviceId.isEmpty) {
        deviceId = await _getDeviceId();
        await StorageUtil.setString(StorageUtil.keyDeviceId, deviceId);
      }

      // 调用设备登录接口
      final response = await _dioClient.post(
        ApiConstants.deviceLogin,
        data: {
          'deviceId': deviceId,
          'platform': _getPlatformName(),
          'appVersion': '1.0.0',
        },
      );

      final data = response.data;
      if (data != null && data['success'] == true) {
        // 保存认证信息
        final token = data['accessToken'] as String?;
        final refreshToken = data['refreshToken'] as String?;
        final employeeId = data['employeeId'] as String?;
        final employeeName = data['employeeName'] as String?;

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
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('设备登录失败: $e');
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
      await _dioClient.post(ApiConstants.logout);
    } catch (_) {
      // 即使接口失败也要清除本地数据
    }

    // 清除本地认证信息
    await StorageUtil.remove(StorageUtil.keyAuthToken);
    await StorageUtil.remove(StorageUtil.keyRefreshToken);
    await StorageUtil.setBool(StorageUtil.keyIsLoggedIn, false);
  }

  /// 获取设备唯一标识
  Future<String> _getDeviceId() async {
    // 简化实现：使用时间戳 + 随机数生成
    // 实际项目中应使用 device_info_plus 获取真实设备标识
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return 'device_${timestamp}_$random';
  }

  /// 获取平台名称
  String _getPlatformName() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }
}
