/// API 地址常量
/// 集中管理所有后端 API 端点地址
library;

class ApiConstants {
  ApiConstants._();

  // ===== 基础配置 =====
  /// API 基础地址（开发环境）
  static const String devBaseUrl = 'https://dev-api.worknav.example.com';
  /// API 基础地址（生产环境）
  static const String prodBaseUrl = 'https://api.worknav.example.com';
  /// 当前使用的基地址
  static const String baseUrl = devBaseUrl;

  // ===== 认证相关 =====
  /// 设备登录（自动登录）
  static const String deviceLogin = '/api/auth/device-login';
  /// 刷新令牌
  static const String refreshToken = '/api/auth/refresh-token';
  /// 登出
  static const String logout = '/api/auth/logout';

  // ===== 任务相关 =====
  /// 获取今日任务列表
  static const String todayTasks = '/api/tasks/today';
  /// 获取任务详情（含步骤）
  static const String taskDetail = '/api/tasks/';
  /// 提交步骤完成
  static const String completeStep = '/api/tasks/{taskId}/steps/{stepId}/complete';
  /// 提交任务完成
  static const String completeTask = '/api/tasks/{taskId}/complete';
  /// 请求帮助
  static const String requestHelp = '/api/tasks/{taskId}/help';

  // ===== 情绪相关 =====
  /// 提交情绪记录
  static const String submitEmotion = '/api/emotions';
  /// 获取今日情绪记录
  static const String todayEmotions = '/api/emotions/today';

  // ===== 沟通相关 =====
  /// 获取常用语列表
  static const String phrases = '/api/communication/phrases';

  // ===== 远程协助相关 =====
  /// 上传求助照片
  static const String uploadPhoto = '/api/assist/upload-photo';
  /// 获取协助回复
  static const String assistReplies = '/api/assist/replies';

  // ===== 通知相关 =====
  /// 获取通知列表
  static const String notifications = '/api/notifications';
  /// 标记通知已读
  static const String markNotificationRead = '/api/notifications/{id}/read';

  // ===== 排班相关 =====
  /// 同步排班信息
  static const String syncSchedule = '/api/schedule/sync';

  // ===== 数据同步 =====
  /// 同步离线数据
  static const String syncOffline = '/api/sync/offline';

  // ===== 超时配置 =====
  /// 连接超时（秒）
  static const int connectTimeout = 10;
  /// 接收超时（秒）
  static const int receiveTimeout = 30;
  /// 发送超时（秒）
  static const int sendTimeout = 30;
}
