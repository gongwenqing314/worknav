/// 音频播放工具
/// 支持预录制音频播放、TTS 语音合成、视觉展示三级降级方案
library;

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// 音频播放降级策略枚举
enum AudioPlaybackStrategy {
  /// 优先级1: 预录制音频文件
  preRecorded,
  /// 优先级2: 系统 TTS
  systemTts,
  /// 优先级3: 视觉展示（回调通知 UI 层）
  visualFallback,
}

/// 视觉展示回调（降级方案3使用）
typedef VisualFallbackCallback = void Function(String text);

class AudioPlayer {
  static final AudioPlayer _instance = AudioPlayer._();
  factory AudioPlayer() => _instance;
  AudioPlayer._();

  final JustAudioPlayer _player = JustAudioPlayer();
  AudioPlaybackStrategy _currentStrategy = AudioPlaybackStrategy.preRecorded;

  /// 当前播放策略
  AudioPlaybackStrategy get currentStrategy => _currentStrategy;

  /// 视觉展示回调（由 UI 层设置）
  VisualFallbackCallback? onVisualFallback;

  /// 初始化音频播放器
  Future<void> init() async {
    await _player.init();
  }

  /// 播放语音提示
  /// [text] 要播放的文字内容
  /// [audioPath] 预录制音频文件路径（可选）
  ///
  /// 降级策略:
  /// 1. 如果提供了 audioPath 且文件存在，播放预录制音频
  /// 2. 否则尝试使用系统 TTS
  /// 3. TTS 不可用时，触发视觉展示回调
  Future<void> speak(String text, {String? audioPath}) async {
    // 策略1: 尝试播放预录制音频
    if (audioPath != null && audioPath.isNotEmpty) {
      try {
        await _player.playFile(audioPath);
        _currentStrategy = AudioPlaybackStrategy.preRecorded;
        debugPrint('音频播放: 使用预录制音频 - $audioPath');
        return;
      } catch (e) {
        debugPrint('预录制音频播放失败: $e，降级到 TTS');
      }
    }

    // 策略2: 尝试使用系统 TTS
    try {
      await _player.speak(text);
      _currentStrategy = AudioPlaybackStrategy.systemTts;
      debugPrint('音频播放: 使用系统 TTS - $text');
      return;
    } catch (e) {
      debugPrint('TTS 播放失败: $e，降级到视觉展示');
    }

    // 策略3: 视觉展示降级
    _currentStrategy = AudioPlaybackStrategy.visualFallback;
    onVisualFallback?.call(text);
    debugPrint('音频播放: 使用视觉展示降级 - $text');
  }

  /// 播放预录制音频文件
  Future<void> playAudioFile(String path) async {
    try {
      await _player.playFile(path);
      _currentStrategy = AudioPlaybackStrategy.preRecorded;
    } catch (e) {
      debugPrint('播放音频文件失败: $e');
    }
  }

  /// 停止播放
  Future<void> stop() async {
    await _player.stop();
  }

  /// 释放资源
  Future<void> dispose() async {
    await _player.dispose();
  }
}

/// JustAudio 播放器封装
class JustAudioPlayer {
  final AudioPlayer _player = AudioPlayer();

  Future<void> init() async {
    // 配置播放器参数
  }

  /// 播放本地文件
  Future<void> playFile(String path) async {
    await _player.setFilePath(path);
    await _player.play();
  }

  /// 播放网络 URL
  Future<void> playUrl(String url) async {
    await _player.setUrl(url);
    await _player.play();
  }

  /// TTS 语音合成（使用系统 TTS 引擎）
  /// 注意: 实际项目中应使用 flutter_tts 包
  Future<void> speak(String text) async {
    // 这里使用 flutter_tts 的简化实现
    // 实际项目中需要初始化 FlutterTts 实例
    try {
      // 模拟 TTS 调用
      // final tts = FlutterTts();
      // await tts.speak(text);
      debugPrint('TTS: $text');
      // 由于 flutter_tts 需要平台特定初始化，
      // 这里抛出异常以触发降级
      throw UnimplementedError('TTS 未初始化');
    } catch (e) {
      rethrow;
    }
  }

  /// 停止播放
  Future<void> stop() async {
    await _player.stop();
  }

  /// 释放资源
  Future<void> dispose() async {
    await _player.dispose();
  }
}
