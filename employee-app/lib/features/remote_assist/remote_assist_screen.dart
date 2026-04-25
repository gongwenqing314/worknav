/// 远程协助页面
/// 拍照发送求助，接收管理员标注图+语音回复
library;

import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/audio_player.dart';
import '../../../core/utils/vibration_util.dart';

/// 远程协助页面
/// 员工可以拍照发送给管理员请求远程指导
/// 管理员可以回复标注图和语音指导
class RemoteAssistScreen extends StatefulWidget {
  const RemoteAssistScreen({super.key});

  @override
  State<RemoteAssistScreen> createState() => _RemoteAssistScreenState();
}

class _RemoteAssistScreenState extends State<RemoteAssistScreen> {
  /// 是否正在拍照
  bool _isCapturing = false;

  /// 是否正在发送
  bool _isSending = false;

  /// 已拍摄的照片路径
  String? _photoPath;

  /// 是否已发送
  bool _isSent = false;

  /// 是否正在等待回复
  bool _isWaitingReply = false;

  /// 是否收到回复
  bool _hasReply = false;

  /// 回复图片路径（模拟）
  String? _replyImagePath;

  /// 回复语音文字（模拟）
  String _replyText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('远程协助'),
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
                  color: AppColors.assistOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.borderRadiusMedium,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.support_agent,
                      size: 32,
                      color: AppColors.assistOrange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '遇到困难了？拍一张照片发给管理员，我们会帮你解决。',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.assistOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spacingXLarge),

              // 拍照区域
              if (!_isSent) ...[
                // 拍照按钮
                Center(
                  child: PhotoCaptureButton(
                    isCapturing: _isCapturing,
                    label: _photoPath != null ? '重新拍照' : '拍照发送',
                    onPressed: _capturePhoto,
                  ),
                ),

                // 已拍照片预览
                if (_photoPath != null) ...[
                  const SizedBox(height: AppDimensions.spacingLarge),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.borderRadiusMedium,
                      ),
                      border: Border.all(color: AppColors.divider, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.borderRadiusMedium - 1,
                      ),
                      child: _buildPhotoPreview(),
                    ),
                  ),

                  const SizedBox(height: AppDimensions.spacingLarge),

                  // 发送按钮
                  SizedBox(
                    height: 64,
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _sendPhoto,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.assistOrange,
                        foregroundColor: AppColors.textOnPrimary,
                        disabledBackgroundColor:
                            AppColors.assistOrange.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.borderRadiusMedium,
                          ),
                        ),
                      ),
                      child: _isSending
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: AppColors.textOnPrimary,
                                strokeWidth: 3,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.send, size: 28),
                                const SizedBox(width: 8),
                                Text(
                                  '发送给管理员',
                                  style: AppTextStyles.buttonLarge.copyWith(
                                    color: AppColors.textOnPrimary,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ],

              // 等待回复状态
              if (_isWaitingReply) ...[
                const SizedBox(height: AppDimensions.spacingXLarge),
                Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.assistOrange,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '管理员正在查看你的照片...',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '请稍等一会儿',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],

              // 收到回复
              if (_hasReply) ...[
                const SizedBox(height: AppDimensions.spacingLarge),
                Container(
                  padding: const EdgeInsets.all(AppDimensions.cardPadding),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.borderRadiusMedium,
                    ),
                    border: Border.all(
                      color: AppColors.primaryGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.primaryGreen,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '管理员回复了',
                            style: AppTextStyles.headlineSmall.copyWith(
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // 回复文字
                      Text(
                        _replyText,
                        style: AppTextStyles.bodyLarge,
                      ),
                      const SizedBox(height: 12),
                      // 播放语音按钮
                      SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            AudioPlayer().speak(_replyText);
                            VibrationUtil.light();
                          },
                          icon: const Icon(Icons.volume_up, size: 28),
                          label: Text(
                            '听语音',
                            style: AppTextStyles.buttonMedium.copyWith(
                              color: AppColors.textOnPrimary,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: AppColors.textOnPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.spacingLarge),

                // 新的求助按钮
                SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _resetState,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: const BorderSide(
                        color: AppColors.assistOrange,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      '继续求助',
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: AppColors.assistOrange,
                      ),
                    ),
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

  /// 拍照
  Future<void> _capturePhoto() async {
    setState(() => _isCapturing = true);

    try {
      // 模拟拍照
      // 实际项目中使用 image_picker:
      // final picker = ImagePicker();
      // final image = await picker.pickImage(source: ImageSource.camera);
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _photoPath = 'captured_photo.jpg';
        _isCapturing = false;
      });

      VibrationUtil.medium();
    } catch (e) {
      setState(() => _isCapturing = false);
    }
  }

  /// 构建照片预览
  Widget _buildPhotoPreview() {
    if (_photoPath != null && File(_photoPath!).existsSync()) {
      return Image.file(
        File(_photoPath!),
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }

    // 模拟照片预览
    return Container(
      color: AppColors.surfaceVariant,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_camera, size: 48, color: AppColors.textHint),
            SizedBox(height: 8),
            Text('照片预览', style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }

  /// 发送照片
  Future<void> _sendPhoto() async {
    setState(() => _isSending = true);

    try {
      // 模拟上传
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isSent = true;
        _isSending = false;
        _isWaitingReply = true;
      });

      VibrationUtil.medium();

      // 模拟管理员回复（5秒后）
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _isWaitingReply = false;
            _hasReply = true;
            _replyText = '做得很好！按照箭头方向把物品放到正确的位置就可以了。加油！';
          });
          VibrationUtil.successPattern();
          AudioPlayer().speak(_replyText);
        }
      });
    } catch (e) {
      setState(() => _isSending = false);
    }
  }

  /// 重置状态，允许新的求助
  void _resetState() {
    setState(() {
      _photoPath = null;
      _isSent = false;
      _isWaitingReply = false;
      _hasReply = false;
      _replyImagePath = null;
      _replyText = '';
    });
  }
}
