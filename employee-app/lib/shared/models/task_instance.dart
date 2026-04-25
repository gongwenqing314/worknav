/// 任务实例模型
/// 员工当天被分配的具体任务
library;

/// 任务状态
enum TaskStatus {
  /// 待执行
  pending,
  /// 进行中
  inProgress,
  /// 已完成
  completed,
  /// 需要帮助
  needHelp,
  /// 已跳过
  skipped,
}

/// 任务实例 - 员工当天被分配的具体任务
class TaskInstance {
  /// 实例 ID
  final String id;
  /// 关联的模板 ID
  final String templateId;
  /// 任务名称
  final String name;
  /// 任务描述
  final String description;
  /// 任务图标 URL
  final String iconUrl;
  /// 任务图标颜色
  final String iconColor;
  /// 当前状态
  TaskStatus status;
  /// 步骤总数
  final int totalSteps;
  /// 已完成步骤数
  int completedSteps;
  /// 当前步骤索引（从0开始）
  int currentStepIndex;
  /// 计划开始时间
  final DateTime scheduledTime;
  /// 实际开始时间
  DateTime? startTime;
  /// 完成时间
  DateTime? completedTime;
  /// 分配的管理员 ID
  final String assignedBy;
  /// 是否离线模式
  bool isOffline;

  TaskInstance({
    required this.id,
    required this.templateId,
    required this.name,
    required this.description,
    required this.iconUrl,
    this.iconColor = '#4CAF50',
    this.status = TaskStatus.pending,
    required this.totalSteps,
    this.completedSteps = 0,
    this.currentStepIndex = 0,
    required this.scheduledTime,
    this.startTime,
    this.completedTime,
    required this.assignedBy,
    this.isOffline = false,
  });

  /// 完成进度百分比 (0.0 - 1.0)
  double get progress {
    if (totalSteps == 0) return 0;
    return completedSteps / totalSteps;
  }

  /// 是否已开始
  bool get hasStarted => status == TaskStatus.inProgress ||
      status == TaskStatus.completed;

  /// 是否已完成
  bool get isCompleted => status == TaskStatus.completed;

  /// 是否需要帮助
  bool get needsHelp => status == TaskStatus.needHelp;

  /// 从 JSON 创建
  factory TaskInstance.fromJson(Map<String, dynamic> json) {
    return TaskInstance(
      id: json['id'] as String,
      templateId: json['templateId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconUrl: json['iconUrl'] as String? ?? '',
      iconColor: json['iconColor'] as String? ?? '#4CAF50',
      status: _parseStatus(json['status'] as String?),
      totalSteps: json['totalSteps'] as int? ?? 0,
      completedSteps: json['completedSteps'] as int? ?? 0,
      currentStepIndex: json['currentStepIndex'] as int? ?? 0,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      completedTime: json['completedTime'] != null
          ? DateTime.parse(json['completedTime'] as String)
          : null,
      assignedBy: json['assignedBy'] as String? ?? '',
      isOffline: json['isOffline'] as bool? ?? false,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'templateId': templateId,
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'iconColor': iconColor,
      'status': status.name,
      'totalSteps': totalSteps,
      'completedSteps': completedSteps,
      'currentStepIndex': currentStepIndex,
      'scheduledTime': scheduledTime.toIso8601String(),
      'startTime': startTime?.toIso8601String(),
      'completedTime': completedTime?.toIso8601String(),
      'assignedBy': assignedBy,
      'isOffline': isOffline,
    };
  }

  /// 解析任务状态字符串
  static TaskStatus _parseStatus(String? statusStr) {
    switch (statusStr) {
      case 'inProgress':
        return TaskStatus.inProgress;
      case 'completed':
        return TaskStatus.completed;
      case 'needHelp':
        return TaskStatus.needHelp;
      case 'skipped':
        return TaskStatus.skipped;
      case 'pending':
      default:
        return TaskStatus.pending;
    }
  }
}
