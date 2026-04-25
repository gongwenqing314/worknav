/// 本地存储工具
/// 封装 SharedPreferences，提供类型安全的存取接口
library;

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageUtil {
  StorageUtil._();

  static SharedPreferences? _prefs;

  /// 初始化（在 main 中调用）
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 确保 SharedPreferences 已初始化
  static SharedPreferences get _instance {
    assert(_prefs != null, 'StorageUtil 未初始化，请先调用 StorageUtil.init()');
    return _prefs!;
  }

  // ===== String =====
  static Future<bool> setString(String key, String value) {
    return _instance.setString(key, value);
  }

  static String? getString(String key, {String? defaultValue}) {
    return _instance.getString(key) ?? defaultValue;
  }

  // ===== int =====
  static Future<bool> setInt(String key, int value) {
    return _instance.setInt(key, value);
  }

  static int? getInt(String key, {int? defaultValue}) {
    return _instance.getInt(key) ?? defaultValue;
  }

  // ===== double =====
  static Future<bool> setDouble(String key, double value) {
    return _instance.setDouble(key, value);
  }

  static double? getDouble(String key, {double? defaultValue}) {
    return _instance.getDouble(key) ?? defaultValue;
  }

  // ===== bool =====
  static Future<bool> setBool(String key, bool value) {
    return _instance.setBool(key, value);
  }

  static bool? getBool(String key, {bool? defaultValue}) {
    return _instance.getBool(key) ?? defaultValue;
  }

  // ===== JSON 对象 =====
  static Future<bool> setJson(String key, Map<String, dynamic> value) {
    return _instance.setString(key, jsonEncode(value));
  }

  static Map<String, dynamic>? getJson(String key) {
    final str = _instance.getString(key);
    if (str == null) return null;
    try {
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ===== JSON 列表 =====
  static Future<bool> setJsonList(String key, List<Map<String, dynamic>> value) {
    return _instance.setString(key, jsonEncode(value));
  }

  static List<Map<String, dynamic>> getJsonList(String key) {
    final str = _instance.getString(key);
    if (str == null) return [];
    try {
      final list = jsonDecode(str) as List;
      return list.map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }

  // ===== 删除和检查 =====
  static Future<bool> remove(String key) {
    return _instance.remove(key);
  }

  static bool containsKey(String key) {
    return _instance.containsKey(key);
  }

  static Future<bool> clear() {
    return _instance.clear();
  }

  // ===== 常用键名 =====
  /// 认证令牌
  static const String keyAuthToken = 'auth_token';
  /// 刷新令牌
  static const String keyRefreshToken = 'refresh_token';
  /// 设备 ID
  static const String keyDeviceId = 'device_id';
  /// 员工 ID
  static const String keyEmployeeId = 'employee_id';
  /// 员工姓名
  static const String keyEmployeeName = 'employee_name';
  /// 是否已登录
  static const String keyIsLoggedIn = 'is_logged_in';
  /// 上次同步时间
  static const String keyLastSyncTime = 'last_sync_time';
  /// 字体大小倍率
  static const String keyFontScale = 'font_scale';
  /// 震动开关
  static const String keyVibrationEnabled = 'vibration_enabled';
  /// 语音播报开关
  static const String keyVoiceEnabled = 'voice_enabled';
}
