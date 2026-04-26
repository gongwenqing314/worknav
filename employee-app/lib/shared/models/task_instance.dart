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

  /// 从 JSON 创建（兼容后端 snake_case 和前端 camelCase）
  factory TaskInstance.fromJson(Map<String, dynamic> json) {
    // 解析步骤列表（后端返回 steps 数组）
    final steps = json['steps'] as List?;
    final totalSteps = steps?.length ?? (json['totalSteps'] as int? ?? (json['total_steps'] as int? ?? 0));

    // 解析计划时间（后端返回 "09:00:00" 格式的时间字符串或完整日期时间）
    DateTime scheduledTime;
    final scheduledTimeStr = json['scheduledTime'] as String? ?? json['scheduled_time'] as String?;
    if (scheduledTimeStr != null) {
      try {
        scheduledTime = DateTime.parse(scheduledTimeStr);
      } catch (_) {
        // 如果只是时间字符串（如 "09:00:00"），结合 scheduled_date 构造日期时间
        final scheduledDateStr = json['scheduledDate'] as String? ?? json['scheduled_date'] as String?;
        if (scheduledDateStr != null) {
          // scheduled_date 可能是 ISO 格式，提取日期部分
          final dateOnly = scheduledDateStr.length > 10 ? scheduledDateStr.substring(0, 10) : scheduledDateStr;
          scheduledTime = DateTime.parse('$dateOnly $scheduledTimeStr');
        } else {
          // 使用今天的日期
          final now = DateTime.now();
          final parts = scheduledTimeStr.split(':');
          scheduledTime = DateTime(now.year, now.month, now.day,
              int.parse(parts[0]), int.parse(parts[1]));
        }
      }
    } else {
      scheduledTime = DateTime.now();
    }

    // 解析开始时间
    DateTime? startTime;
    final startTimeStr = json['startTime'] as String? ?? json['started_at'] as String?;
    if (startTimeStr != null && startTimeStr.isNotEmpty && startTimeStr != 'null') {
      try {
        startTime = DateTime.parse(startTimeStr);
      } catch (_) {
        startTime = null;
      }
    }

    // 解析完成时间
    DateTime? completedTime;
    final completedTimeStr = json['completedTime'] as String? ?? json['completed_at'] as String?;
    if (completedTimeStr != null && completedTimeStr.isNotEmpty && completedTimeStr != 'null') {
      try {
        completedTime = DateTime.parse(completedTimeStr);
      } catch (_) {
        completedTime = null;
      }
    }

    return TaskInstance(
      id: (json['id'] ?? json['instanceId'] ?? '').toString(),
      templateId: (json['templateId'] ?? json['template_id'] ?? '').toString(),
      name: json['name'] as String? ?? json['template_title'] as String? ?? '',
      description: json['description'] as String? ?? json['template_description'] as String? ?? '',
      iconUrl: json['iconUrl'] as String? ?? json['icon_url'] as String? ?? '',
      iconColor: json['iconColor'] as String? ?? json['icon_color'] as String? ?? '#4CAF50',
      status: _parseStatus(json['status'] as String?),
      totalSteps: totalSteps,
      completedSteps: json['completedSteps'] as int? ?? json['completed_steps'] as int? ?? 0,
      currentStepIndex: json['currentStepIndex'] as int? ?? json['current_step_index'] as int? ?? 0,
      scheduledTime: scheduledTime,
      startTime: startTime,
      completedTime: completedTime,
      assignedBy: (json['assignedBy'] ?? json['assigned_by'] ?? '').toString(),
      isOffline: json['isOffline'] as bool? ?? json['is_offline'] as bool? ?? false,
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
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'completed':
        return TaskStatus.completed;
      case 'needHelp':
      case 'need_help':
        return TaskStatus.needHelp;
      case 'skipped':
        return TaskStatus.skipped;
      case 'assigned':
      case 'pending':
      default:
        return TaskStatus.pending;
    }
  }
}
