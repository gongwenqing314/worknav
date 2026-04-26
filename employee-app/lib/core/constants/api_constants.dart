/// API 地址常量
/// 集中管理所有后端 API 端点地址
library;

class ApiConstants {
  ApiConstants._();

  // ===== 基础配置 =====
  /// API 基础地址（开发环境 - 同源部署，使用相对路径）
  static const String devBaseUrl = '/api/v1';
  /// API 基础地址（生产环境）
  static const String prodBaseUrl = '/api/v1';
  /// 当前使用的基地址
  static const String baseUrl = devBaseUrl;

  // ===== 认证相关 =====
  /// 设备登录（自动登录）
  static const String deviceLogin = '/auth/device-login';
  /// 刷新令牌
  static const String refreshToken = '/auth/refresh-token';
  /// 登出
  static const String logout = '/auth/logout';

  // ===== 任务相关 =====
  /// 获取今日任务列表
  static const String todayTasks = '/tasks/today';
  /// 获取任务详情（含步骤）
  static const String taskDetail = '/tasks/';
  /// 提交步骤完成
  static const String completeStep = '/tasks/{taskId}/steps/{stepId}/complete';
  /// 提交任务完成
  static const String completeTask = '/tasks/{taskId}/complete';
  /// 请求帮助
  static const String requestHelp = '/tasks/{taskId}/help';

  // ===== 情绪相关 =====
  /// 提交情绪记录
  static const String submitEmotion = '/emotions/record';
  /// 获取今日情绪记录
  static const String todayEmotions = '/emotions/today';

  // ===== 沟通相关 =====
  /// 获取常用语列表
  static const String phrases = '/communication/phrases';

  // ===== 远程协助相关 =====
  /// 上传求助照片
  static const String uploadPhoto = '/remote-assist/sessions';
  /// 获取协助回复
  static const String assistReplies = '/remote-assist/sessions/{sessionId}/messages';

  // ===== 通知相关 =====
  /// 获取通知列表
  static const String notifications = '/notifications';
  /// 标记通知已读
  static const String markNotificationRead = '/notifications/{id}/read';

  // ===== 排班相关 =====
  /// 同步排班信息
  static const String syncSchedule = '/schedules/week';

  // ===== 数据同步 =====
  /// 同步离线数据
  static const String syncOffline = '/sync/offline';

  // ===== 超时配置 =====
  /// 连接超时（秒）
  static const int connectTimeout = 10;
  /// 接收超时（秒）
  static const int receiveTimeout = 30;
  /// 发送超时（秒）
  static const int sendTimeout = 30;
}
