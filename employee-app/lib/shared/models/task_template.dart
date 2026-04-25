/// 任务模板模型
/// 定义任务的基本结构，由管理员创建
library;

/// 任务模板 - 管理员创建的任务定义
class TaskTemplate {
  /// 模板 ID
  final String id;
  /// 任务名称
  final String name;
  /// 任务描述
  final String description;
  /// 任务图标 URL
  final String iconUrl;
  /// 任务图标颜色（十六进制）
  final String iconColor;
  /// 步骤列表
  final List<TaskStep> steps;
  /// 预计完成时间（分钟）
  final int estimatedMinutes;
  /// 创建时间
  final DateTime createdAt;
  /// 更新时间
  final DateTime updatedAt;

  TaskTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    this.iconColor = '#4CAF50',
    required this.steps,
    this.estimatedMinutes = 30,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从 JSON 创建
  factory TaskTemplate.fromJson(Map<String, dynamic> json) {
    return TaskTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconUrl: json['iconUrl'] as String? ?? '',
      iconColor: json['iconColor'] as String? ?? '#4CAF50',
      steps: (json['steps'] as List?)
              ?.map((s) => TaskStep.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 30,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'iconColor': iconColor,
      'steps': steps.map((s) => s.toJson()).toList(),
      'estimatedMinutes': estimatedMinutes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// 任务步骤 - 模板中的单个步骤定义
class TaskStep {
  /// 步骤序号（从1开始）
  final int order;
  /// 步骤 ID
  final String id;
  /// 步骤标题
  final String title;
  /// 步骤详细说明
  final String instruction;
  /// 步骤配图 URL
  final String imageUrl;
  /// 语音提示音频 URL
  final String audioUrl;
  /// 预录制音频文件名（本地 assets）
  final String audioAsset;

  TaskStep({
    required this.order,
    required this.id,
    required this.title,
    required this.instruction,
    this.imageUrl = '',
    this.audioUrl = '',
    this.audioAsset = '',
  });

  factory TaskStep.fromJson(Map<String, dynamic> json) {
    return TaskStep(
      order: json['order'] as int,
      id: json['id'] as String,
      title: json['title'] as String,
      instruction: json['instruction'] as String,
      imageUrl: json['imageUrl'] as String? ?? '',
      audioUrl: json['audioUrl'] as String? ?? '',
      audioAsset: json['audioAsset'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order': order,
      'id': id,
      'title': title,
      'instruction': instruction,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'audioAsset': audioAsset,
    };
  }
}
