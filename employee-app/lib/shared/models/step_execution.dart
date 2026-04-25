/// 步骤执行记录模型
/// 记录每个步骤的执行状态
library;

/// 步骤执行状态
enum StepExecutionStatus {
  /// 未开始
  notStarted,
  /// 进行中
  inProgress,
  /// 已完成
  completed,
  /// 需要帮助
  needHelp,
}

/// 步骤执行记录
class StepExecution {
  /// 记录 ID
  final String id;
  /// 任务实例 ID
  final String taskInstanceId;
  /// 步骤 ID
  final String stepId;
  /// 步骤序号
  final int stepOrder;
  /// 步骤标题
  final String title;
  /// 步骤说明
  final String instruction;
  /// 步骤配图 URL
  final String imageUrl;
  /// 语音音频路径
  final String audioPath;
  /// 执行状态
  StepExecutionStatus status;
  /// 开始时间
  DateTime? startTime;
  /// 完成时间
  DateTime? completedTime;
  /// 是否已重新查看（已完成步骤被回看）
  bool isReviewed;
  /// 重新查看次数
  int reviewCount;

  StepExecution({
    required this.id,
    required this.taskInstanceId,
    required this.stepId,
    required this.stepOrder,
    required this.title,
    required this.instruction,
    this.imageUrl = '',
    this.audioPath = '',
    this.status = StepExecutionStatus.notStarted,
    this.startTime,
    this.completedTime,
    this.isReviewed = false,
    this.reviewCount = 0,
  });

  /// 是否已完成
  bool get isCompleted => status == StepExecutionStatus.completed;

  /// 从 JSON 创建
  factory StepExecution.fromJson(Map<String, dynamic> json) {
    return StepExecution(
      id: json['id'] as String,
      taskInstanceId: json['taskInstanceId'] as String,
      stepId: json['stepId'] as String,
      stepOrder: json['stepOrder'] as int,
      title: json['title'] as String,
      instruction: json['instruction'] as String,
      imageUrl: json['imageUrl'] as String? ?? '',
      audioPath: json['audioPath'] as String? ?? '',
      status: _parseStatus(json['status'] as String?),
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      completedTime: json['completedTime'] != null
          ? DateTime.parse(json['completedTime'] as String)
          : null,
      isReviewed: json['isReviewed'] as bool? ?? false,
      reviewCount: json['reviewCount'] as int? ?? 0,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskInstanceId': taskInstanceId,
      'stepId': stepId,
      'stepOrder': stepOrder,
      'title': title,
      'instruction': instruction,
      'imageUrl': imageUrl,
      'audioPath': audioPath,
      'status': status.name,
      'startTime': startTime?.toIso8601String(),
      'completedTime': completedTime?.toIso8601String(),
      'isReviewed': isReviewed,
      'reviewCount': reviewCount,
    };
  }

  /// 解析步骤状态
  static StepExecutionStatus _parseStatus(String? statusStr) {
    switch (statusStr) {
      case 'inProgress':
        return StepExecutionStatus.inProgress;
      case 'completed':
        return StepExecutionStatus.completed;
      case 'needHelp':
        return StepExecutionStatus.needHelp;
      case 'notStarted':
      default:
        return StepExecutionStatus.notStarted;
    }
  }
}
