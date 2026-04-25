/// 常用语模型
/// 沟通板中使用的预设短语
library;

/// 常用语
class CommPhrase {
  /// 短语 ID
  final String id;
  /// 短语文字内容
  final String text;
  /// 短语显示图标名称（Material Icons 名称）
  final String iconName;
  /// 短语分类
  final String category;
  /// 排序序号
  final int order;
  /// 预录制音频路径（本地 assets）
  final String audioAsset;
  /// 是否启用
  final bool isEnabled;

  CommPhrase({
    required this.id,
    required this.text,
    required this.iconName,
    this.category = 'general',
    this.order = 0,
    this.audioAsset = '',
    this.isEnabled = true,
  });

  /// 从 JSON 创建
  factory CommPhrase.fromJson(Map<String, dynamic> json) {
    return CommPhrase(
      id: json['id'] as String,
      text: json['text'] as String,
      iconName: json['iconName'] as String,
      category: json['category'] as String? ?? 'general',
      order: json['order'] as int? ?? 0,
      audioAsset: json['audioAsset'] as String? ?? '',
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'iconName': iconName,
      'category': category,
      'order': order,
      'audioAsset': audioAsset,
      'isEnabled': isEnabled,
    };
  }

  /// 默认常用语列表（沟通板预设）
  static List<CommPhrase> get defaultPhrases => [
        CommPhrase(
          id: 'phrase_1',
          text: '我需要帮助',
          iconName: 'help',
          category: 'help',
          order: 1,
        ),
        CommPhrase(
          id: 'phrase_2',
          text: '我完成了',
          iconName: 'check_circle',
          category: 'status',
          order: 2,
        ),
        CommPhrase(
          id: 'phrase_3',
          text: '我不明白',
          iconName: 'question_mark',
          category: 'help',
          order: 3,
        ),
        CommPhrase(
          id: 'phrase_4',
          text: '请等一下',
          iconName: 'pause_circle',
          category: 'general',
          order: 4,
        ),
        CommPhrase(
          id: 'phrase_5',
          text: '我需要休息',
          iconName: 'coffee',
          category: 'general',
          order: 5,
        ),
        CommPhrase(
          id: 'phrase_6',
          text: '好的，我知道了',
          iconName: 'thumb_up',
          category: 'status',
          order: 6,
        ),
        CommPhrase(
          id: 'phrase_7',
          text: '谢谢',
          iconName: 'favorite',
          category: 'general',
          order: 7,
        ),
        CommPhrase(
          id: 'phrase_8',
          text: '我不舒服',
          iconName: 'sick',
          category: 'help',
          order: 8,
        ),
      ];
}
