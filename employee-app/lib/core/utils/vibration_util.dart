/// 震动工具
/// 提供不同强度的震动反馈，增强操作感知
library;

import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

class VibrationUtil {
  VibrationUtil._();

  /// 轻触震动 - 用于按钮点击等轻量反馈
  static Future<void> light() async {
    try {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) {
        await Vibration.vibrate(duration: 50, amplitude: 50);
      }
    } catch (e) {
      debugPrint('震动失败: $e');
    }
  }

  /// 中等震动 - 用于步骤完成等确认反馈
  static Future<void> medium() async {
    try {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) {
        await Vibration.vibrate(duration: 100, amplitude: 128);
      }
    } catch (e) {
      debugPrint('震动失败: $e');
    }
  }

  /// 重度震动 - 用于警告、错误等需要引起注意的场景
  static Future<void> heavy() async {
    try {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) {
        await Vibration.vibrate(duration: 300, amplitude: 255);
      }
    } catch (e) {
      debugPrint('震动失败: $e');
    }
  }

  /// 成功震动模式 - 短-短-长，用于任务完成庆祝
  static Future<void> successPattern() async {
    try {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) {
        await Vibration.vibrate(pattern: [50, 50, 50, 50, 200]);
      }
    } catch (e) {
      debugPrint('震动失败: $e');
    }
  }

  /// 警告震动模式 - 长-短-长，用于需要帮助等紧急场景
  static Future<void> warningPattern() async {
    try {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) {
        await Vibration.vibrate(pattern: [200, 100, 200, 100, 200]);
      }
    } catch (e) {
      debugPrint('震动失败: $e');
    }
  }

  /// 取消震动
  static Future<void> cancel() async {
    try {
      await Vibration.cancel();
    } catch (e) {
      debugPrint('取消震动失败: $e');
    }
  }
}
