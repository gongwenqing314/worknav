/// 通知模型
/// 应用内通知和提醒
library;

/// 通知类型
enum NotificationType {
  /// 任务提醒
  taskReminder,
  /// 任务分配
  taskAssigned,
  /// 远程协助回复
  assistReply,
  /// 情绪关注
  emotionAlert,
  /// 系统通知
  system,
}

/// 通知
class AppNotification {
  /// 通知 ID
  final String id;
  /// 通知类型
  final NotificationType type;
  /// 通知标题
  final String title;
  /// 通知内容
  final String body;
  /// 创建时间
  final DateTime createdAt;
  /// 是否已读
  bool isRead;
  /// 关联的任务 ID（可选）
  final String? taskId;
  /// 关联数据
  final Map<String, dynamic>? extraData;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.taskId,
    this.extraData,
  });

  /// 从 JSON 创建
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: _parseType(json['type'] as String?),
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      taskId: json['taskId'] as String?,
      extraData: json['extraData'] as Map<String, dynamic>?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'taskId': taskId,
      'extraData': extraData,
    };
  }

  /// 解析通知类型
  static NotificationType _parseType(String? typeStr) {
    switch (typeStr) {
      case 'taskReminder':
        return NotificationType.taskReminder;
      case 'taskAssigned':
        return NotificationType.taskAssigned;
      case 'assistReply':
        return NotificationType.assistReply;
      case 'emotionAlert':
        return NotificationType.emotionAlert;
      case 'system':
        return NotificationType.system;
      default:
        return NotificationType.system;
    }
  }
}
