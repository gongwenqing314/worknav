/// 情绪记录模型
/// 记录员工的情绪状态
library;

/// 情绪类型
enum EmotionType {
  /// 很开心
  veryHappy,
  /// 开心
  happy,
  /// 一般
  neutral,
  /// 不开心
  unhappy,
  /// 很不开心
  veryUnhappy,
  /// 需要帮助
  needHelp,
}

/// 情绪记录
class EmotionRecord {
  /// 记录 ID
  final String id;
  /// 情绪类型
  final EmotionType emotionType;
  /// 记录时间
  final DateTime recordedAt;
  /// 附加备注（可选）
  final String note;
  /// 是否已通知管理员
  bool isNotified;
  /// 通知时间
  DateTime? notifiedAt;

  EmotionRecord({
    required this.id,
    required this.emotionType,
    required this.recordedAt,
    this.note = '',
    this.isNotified = false,
    this.notifiedAt,
  });

  /// 情绪是否为消极（需要关注）
  bool get isNegative =>
      emotionType == EmotionType.unhappy ||
      emotionType == EmotionType.veryUnhappy ||
      emotionType == EmotionType.needHelp;

  /// 情绪显示名称
  String get emotionName {
    switch (emotionType) {
      case EmotionType.veryHappy:
        return '很开心';
      case EmotionType.happy:
        return '开心';
      case EmotionType.neutral:
        return '一般';
      case EmotionType.unhappy:
        return '不开心';
      case EmotionType.veryUnhappy:
        return '很不开心';
      case EmotionType.needHelp:
        return '需要帮助';
    }
  }

  /// 情绪对应的 Emoji
  String get emoji {
    switch (emotionType) {
      case EmotionType.veryHappy:
        return '😄';
      case EmotionType.happy:
        return '🙂';
      case EmotionType.neutral:
        return '😐';
      case EmotionType.unhappy:
        return '😟';
      case EmotionType.veryUnhappy:
        return '😢';
      case EmotionType.needHelp:
        return '🆘';
    }
  }

  /// 情绪对应的颜色值
  int get colorValue {
    switch (emotionType) {
      case EmotionType.veryHappy:
        return 0xFF4CAF50; // 绿色
      case EmotionType.happy:
        return 0xFF8BC34A; // 浅绿
      case EmotionType.neutral:
        return 0xFFFFC107; // 黄色
      case EmotionType.unhappy:
        return 0xFFFF9800; // 橙色
      case EmotionType.veryUnhappy:
        return 0xFFF44336; // 红色
      case EmotionType.needHelp:
        return 0xFF9C27B0; // 紫色
    }
  }

  /// 从 JSON 创建
  factory EmotionRecord.fromJson(Map<String, dynamic> json) {
    return EmotionRecord(
      id: json['id'] as String,
      emotionType: _parseEmotionType(json['emotionType'] as String?),
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      note: json['note'] as String? ?? '',
      isNotified: json['isNotified'] as bool? ?? false,
      notifiedAt: json['notifiedAt'] != null
          ? DateTime.parse(json['notifiedAt'] as String)
          : null,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'emotionType': emotionType.name,
      'recordedAt': recordedAt.toIso8601String(),
      'note': note,
      'isNotified': isNotified,
      'notifiedAt': notifiedAt?.toIso8601String(),
    };
  }

  /// 解析情绪类型
  static EmotionType _parseEmotionType(String? typeStr) {
    switch (typeStr) {
      case 'veryHappy':
        return EmotionType.veryHappy;
      case 'happy':
        return EmotionType.happy;
      case 'neutral':
        return EmotionType.neutral;
      case 'unhappy':
        return EmotionType.unhappy;
      case 'veryUnhappy':
        return EmotionType.veryUnhappy;
      case 'needHelp':
        return EmotionType.needHelp;
      default:
        return EmotionType.neutral;
    }
  }
}
