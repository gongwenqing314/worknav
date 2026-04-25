/// 沟通板页面
/// 提供常用语大按钮，点击发声，辅助沟通
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/audio_player.dart';
import '../../../shared/models/comm_phrase.dart';
import '../../../shared/widgets/loading_indicator.dart';
import 'widgets/phrase_button.dart';
import 'widgets/text_display_overlay.dart';

/// 沟通板页面
/// 以大图标按钮展示常用语，点击后播放语音并展示文字
/// 语音播报降级方案:
/// 1. 预录制音频文件（just_audio 播放）
/// 2. 系统 TTS（flutter_tts）
/// 3. 视觉展示（放大文字+闪烁边框）
class CommunicationScreen extends StatefulWidget {
  const CommunicationScreen({super.key});

  @override
  State<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen> {
  /// 常用语列表
  List<CommPhrase> _phrases = [];
  /// 加载状态
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPhrases();
  }

  /// 加载常用语列表
  Future<void> _loadPhrases() async {
    setState(() => _isLoading = true);

    try {
      // 模拟网络请求
      await Future.delayed(const Duration(milliseconds: 500));
      // 使用默认常用语列表
      _phrases = CommPhrase.defaultPhrases;
    } catch (e) {
      // 加载失败，使用默认列表
      _phrases = CommPhrase.defaultPhrases;
    }

    setState(() => _isLoading = false);
  }

  /// 处理常用语点击
  void _onPhraseTapped(CommPhrase phrase) {
    // 播放语音（三级降级方案）
    AudioPlayer().speak(
      phrase.text,
      audioPath: phrase.audioAsset.isNotEmpty ? phrase.audioAsset : null,
    );

    // 展示文字浮层
    TextDisplayOverlay.show(context, text: phrase.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('沟通板'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const LoadingIndicator(message: '正在加载...')
            : _buildContent(),
      ),
    );
  }

  /// 构建页面内容
  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 页面说明
          Container(
            padding: const EdgeInsets.all(AppDimensions.cardPadding),
            decoration: BoxDecoration(
              color: AppColors.commTeal.withOpacity(0.1),
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusMedium),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.touch_app,
                  size: 32,
                  color: AppColors.commTeal,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '点击下面的按钮来表达你想说的话',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.commTeal,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.spacingLarge),

          // 常用语按钮网格（2列布局）
          _buildPhraseGrid(),

          const SizedBox(height: AppDimensions.bottomNavHeight),
        ],
      ),
    );
  }

  /// 构建常用语按钮网格
  Widget _buildPhraseGrid() {
    // 按分类分组
    final helpPhrases = _phrases.where((p) => p.category == 'help').toList();
    final statusPhrases =
        _phrases.where((p) => p.category == 'status').toList();
    final generalPhrases =
        _phrases.where((p) => p.category == 'general').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 求助类
        if (helpPhrases.isNotEmpty) ...[
          _buildCategoryLabel('需要帮助时', AppColors.primaryRed),
          const SizedBox(height: AppDimensions.spacingSmall),
          Wrap(
            spacing: AppDimensions.spacingMedium,
            runSpacing: AppDimensions.spacingMedium,
            children: helpPhrases
                .map((p) => SizedBox(
                      width: (MediaQuery.of(context).size.width -
                              AppDimensions.pagePadding * 2 -
                              AppDimensions.spacingMedium) /
                          2,
                      child: PhraseButton(
                        phrase: p,
                        onTap: () => _onPhraseTapped(p),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: AppDimensions.spacingLarge),
        ],

        // 状态类
        if (statusPhrases.isNotEmpty) ...[
          _buildCategoryLabel('表达状态', AppColors.primaryGreen),
          const SizedBox(height: AppDimensions.spacingSmall),
          Wrap(
            spacing: AppDimensions.spacingMedium,
            runSpacing: AppDimensions.spacingMedium,
            children: statusPhrases
                .map((p) => SizedBox(
                      width: (MediaQuery.of(context).size.width -
                              AppDimensions.pagePadding * 2 -
                              AppDimensions.spacingMedium) /
                          2,
                      child: PhraseButton(
                        phrase: p,
                        onTap: () => _onPhraseTapped(p),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: AppDimensions.spacingLarge),
        ],

        // 通用类
        if (generalPhrases.isNotEmpty) ...[
          _buildCategoryLabel('常用表达', AppColors.primaryBlue),
          const SizedBox(height: AppDimensions.spacingSmall),
          Wrap(
            spacing: AppDimensions.spacingMedium,
            runSpacing: AppDimensions.spacingMedium,
            children: generalPhrases
                .map((p) => SizedBox(
                      width: (MediaQuery.of(context).size.width -
                              AppDimensions.pagePadding * 2 -
                              AppDimensions.spacingMedium) /
                          2,
                      child: PhraseButton(
                        phrase: p,
                        onTap: () => _onPhraseTapped(p),
                      ),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  /// 构建分类标签
  Widget _buildCategoryLabel(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
