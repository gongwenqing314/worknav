/// 设置页面
/// 提供应用设置选项：字体大小、震动、语音播报等
library;

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/storage_util.dart';

/// 设置页面
/// 提供无障碍相关的设置选项
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// 震动开关
  bool _vibrationEnabled = true;

  /// 语音播报开关
  bool _voiceEnabled = true;

  /// 字体大小倍率
  double _fontScale = 1.0;

  /// 是否正在加载
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    final vibration = StorageUtil.getBool(
      StorageUtil.keyVibrationEnabled,
      defaultValue: true,
    );
    final voice = StorageUtil.getBool(
      StorageUtil.keyVoiceEnabled,
      defaultValue: true,
    );
    final fontScale = StorageUtil.getDouble(
      StorageUtil.keyFontScale,
      defaultValue: 1.0,
    );

    setState(() {
      _vibrationEnabled = vibration ?? true;
      _voiceEnabled = voice ?? true;
      _fontScale = fontScale ?? 1.0;
      _isLoading = false;
    });
  }

  /// 保存震动设置
  Future<void> _setVibrationEnabled(bool value) async {
    await StorageUtil.setBool(StorageUtil.keyVibrationEnabled, value);
    setState(() => _vibrationEnabled = value);
  }

  /// 保存语音播报设置
  Future<void> _setVoiceEnabled(bool value) async {
    await StorageUtil.setBool(StorageUtil.keyVoiceEnabled, value);
    setState(() => _voiceEnabled = value);
  }

  /// 保存字体大小
  Future<void> _setFontScale(double value) async {
    await StorageUtil.setDouble(StorageUtil.keyFontScale, value);
    setState(() => _fontScale = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryGreen,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ===== 无障碍设置 =====
                    _buildSectionTitle('无障碍设置'),

                    // 震动反馈开关
                    _buildSwitchTile(
                      icon: Icons.vibration,
                      iconColor: AppColors.primaryBlue,
                      title: '震动反馈',
                      subtitle: '操作时提供震动提示',
                      value: _vibrationEnabled,
                      onChanged: _setVibrationEnabled,
                    ),

                    // 语音播报开关
                    _buildSwitchTile(
                      icon: Icons.volume_up,
                      iconColor: AppColors.primaryGreen,
                      title: '语音播报',
                      subtitle: '自动朗读步骤说明和提示信息',
                      value: _voiceEnabled,
                      onChanged: _setVoiceEnabled,
                    ),

                    const SizedBox(height: AppDimensions.spacingLarge),

                    // ===== 显示设置 =====
                    _buildSectionTitle('显示设置'),

                    // 字体大小
                    _buildFontScaleTile(),

                    const SizedBox(height: AppDimensions.spacingLarge),

                    // ===== 数据管理 =====
                    _buildSectionTitle('数据管理'),

                    // 同步状态
                    _buildInfoTile(
                      icon: Icons.cloud_sync,
                      iconColor: AppColors.commTeal,
                      title: '数据同步',
                      subtitle: '上次同步: 刚刚',
                      trailing: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('正在同步...'),
                              backgroundColor: AppColors.primaryGreen,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.commTeal,
                          foregroundColor: AppColors.textOnPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          '立即同步',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textOnPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // 清除缓存
                    _buildActionTile(
                      icon: Icons.delete_outline,
                      iconColor: AppColors.primaryRed,
                      title: '清除缓存',
                      subtitle: '清除本地缓存数据',
                      onTap: () => _showClearCacheDialog(context),
                    ),

                    const SizedBox(height: AppDimensions.spacingLarge),

                    // ===== 关于 =====
                    _buildSectionTitle('关于'),

                    // 版本信息
                    _buildInfoTile(
                      icon: Icons.info_outline,
                      iconColor: AppColors.textHint,
                      title: '版本',
                      subtitle: '工作导航 v1.0.0',
                    ),

                    const SizedBox(height: AppDimensions.bottomNavHeight),
                  ],
                ),
              ),
      ),
    );
  }

  /// 构建分区标题
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textHint,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 构建开关设置项
  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        secondary: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.bodySmall,
        ),
        activeColor: AppColors.primaryGreen,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
      ),
    );
  }

  /// 构建字体大小设置项
  Widget _buildFontScaleTile() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.emotionPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.text_fields,
                  color: AppColors.emotionPurple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '字体大小',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '调整文字显示大小',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 字体大小滑块
          Row(
            children: [
              Text(
                '小',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textHint,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _fontScale,
                  min: 0.8,
                  max: 1.5,
                  divisions: 7,
                  activeColor: AppColors.emotionPurple,
                  label: '${(_fontScale * 100).toInt()}%',
                  onChanged: _setFontScale,
                ),
              ),
              Text(
                '大',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
          // 预览文字
          Center(
            child: Text(
              '预览文字 AaBbCc',
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 20 * _fontScale,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建信息展示项
  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  /// 构建操作项
  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textHint,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  /// 显示清除缓存确认对话框
  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('清除缓存', style: AppTextStyles.headlineSmall),
          content: Text(
            '确定要清除本地缓存数据吗？这不会影响你的账号信息。',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('取消', style: AppTextStyles.buttonMedium),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('缓存已清除'),
                    backgroundColor: AppColors.primaryGreen,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: AppColors.textOnPrimary,
              ),
              child: Text(
                '确定清除',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: AppColors.textOnPrimary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
