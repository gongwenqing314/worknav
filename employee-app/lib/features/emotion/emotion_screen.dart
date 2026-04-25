/// 情绪表达页面
/// 情绪温度计：5-6个情绪卡片，消极情绪触发确认通知
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/audio_player.dart';
import '../../../core/utils/vibration_util.dart';
import '../../../shared/models/emotion_record.dart';
import 'widgets/emotion_card.dart';
import 'widgets/emotion_confirm_dialog.dart';

/// 情绪表达页面
/// 以情绪温度计的形式展示不同情绪等级
/// 选择消极情绪时会触发确认对话框，通知管理员关注
class EmotionScreen extends StatefulWidget {
  const EmotionScreen({super.key});

  @override
  State<EmotionScreen> createState() => _EmotionScreenState();
}

class _EmotionScreenState extends State<EmotionScreen> {
  /// 当前选中的情绪类型
  EmotionType? _selectedEmotion;

  /// 是否正在提交
  bool _isSubmitting = false;

  /// 最近一次提交的情绪记录
  EmotionRecord? _lastRecord;

  /// 所有可选的情绪类型（从积极到消极排列）
  final List<EmotionType> _emotionTypes = [
    EmotionType.veryHappy,
    EmotionType.happy,
    EmotionType.neutral,
    EmotionType.unhappy,
    EmotionType.veryUnhappy,
    EmotionType.needHelp,
  ];

  /// 处理情绪选择
  Future<void> _onEmotionSelected(EmotionType type) async {
    setState(() {
      _selectedEmotion = type;
    });

    // 创建临时记录以获取信息
    final tempRecord = EmotionRecord(
      id: '',
      emotionType: type,
      recordedAt: DateTime.now(),
    );

    // 播放语音反馈
    final feedbackText = _getFeedbackText(type);
    AudioPlayer().speak(feedbackText);
    VibrationUtil.light();

    // 如果是消极情绪，显示确认对话框
    if (tempRecord.isNegative) {
      VibrationUtil.warningPattern();
      final confirmed = await EmotionConfirmDialog.show(
        context,
        emotionName: tempRecord.emotionName,
      );

      if (confirmed != true) {
        // 用户取消，清除选择
        setState(() => _selectedEmotion = null);
        return;
      }
    }

    // 提交情绪记录
    _submitEmotion(type);
  }

  /// 获取反馈文字
  String _getFeedbackText(EmotionType type) {
    switch (type) {
      case EmotionType.veryHappy:
        return '很高兴你今天心情很好！';
      case EmotionType.happy:
        return '不错哦，继续保持好心情！';
      case EmotionType.neutral:
        return '好的，已记录你的心情。';
      case EmotionType.unhappy:
        return '别担心，管理员会来关心你的。';
      case EmotionType.veryUnhappy:
        return '我们很关心你，管理员马上来。';
      case EmotionType.needHelp:
        return '别担心，我们会帮助你的。';
    }
  }

  /// 提交情绪记录
  Future<void> _submitEmotion(EmotionType type) async {
    setState(() => _isSubmitting = true);

    try {
      // 模拟提交
      await Future.delayed(const Duration(milliseconds: 500));

      final record = EmotionRecord(
        id: 'emotion_${DateTime.now().millisecondsSinceEpoch}',
        emotionType: type,
        recordedAt: DateTime.now(),
        isNotified: EmotionRecord(
          id: '',
          emotionType: type,
          recordedAt: DateTime.now(),
        ).isNegative,
      );

      setState(() {
        _lastRecord = record;
        _isSubmitting = false;
      });

      // 显示成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '已记录你的心情：${record.emotionName}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textOnPrimary,
              ),
            ),
            backgroundColor: AppColors.primaryGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '记录失败，请重试',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textOnPrimary,
              ),
            ),
            backgroundColor: AppColors.primaryRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('我的心情'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 页面说明
              Container(
                padding: const EdgeInsets.all(AppDimensions.cardPadding),
                decoration: BoxDecoration(
                  color: AppColors.emotionPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.borderRadiusMedium,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.sentiment_satisfied_alt,
                      size: 32,
                      color: AppColors.emotionPurple,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '你现在感觉怎么样？选择最接近的心情吧。',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.emotionPurple,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spacingLarge),

              // 情绪温度计标题
              Text(
                '心情温度计',
                style: AppTextStyles.headlineMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 4),

              // 温度计指示条
              Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.primaryGreen,
                      AppColors.taskPending,
                      AppColors.primaryRed,
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.spacingLarge),

              // 情绪卡片列表
              ...List.generate(_emotionTypes.length, (index) {
                final type = _emotionTypes[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < _emotionTypes.length - 1
                        ? AppDimensions.spacingMedium
                        : 0,
                  ),
                  child: EmotionCard(
                    emotionType: type,
                    isSelected: _selectedEmotion == type,
                    onTap: _isSubmitting
                        ? null
                        : () => _onEmotionSelected(type),
                  ),
                );
              }),

              // 最近记录
              if (_lastRecord != null) ...[
                const SizedBox(height: AppDimensions.spacingLarge),
                Container(
                  padding: const EdgeInsets.all(AppDimensions.cardPadding),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.borderRadiusMedium,
                    ),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _lastRecord!.emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '最近记录：${_lastRecord!.emotionName}',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppDimensions.bottomNavHeight),
            ],
          ),
        ),
      ),
    );
  }
}
