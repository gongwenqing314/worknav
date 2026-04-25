/// 情绪服务
/// 提交情绪记录、获取历史记录
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/emotion_record.dart';

/// 情绪服务
class EmotionService {
  final DioClient _dioClient;

  EmotionService(this._dioClient);

  /// 缓存键
  static const String _cacheKeyTodayEmotions = 'cache_today_emotions';

  /// 提交情绪记录
  /// [emotionType] 情绪类型
  /// [note] 附加备注
  /// 返回是否提交成功
  Future<EmotionRecord?> submitEmotion({
    required EmotionType emotionType,
    String note = '',
  }) async {
    final record = EmotionRecord(
      id: 'emotion_${DateTime.now().millisecondsSinceEpoch}',
      emotionType: emotionType,
      recordedAt: DateTime.now(),
      note: note,
    );

    try {
      final response = await _dioClient.post(
        ApiConstants.submitEmotion,
        data: record.toJson(),
      );

      final data = response.data;
      if (data != null && data['success'] == true) {
        // 缓存记录
        await _cacheEmotion(record);
        return record;
      }
      return null;
    } catch (e) {
      debugPrint('提交情绪记录失败: $e');
      // 离线时也缓存
      await _cacheEmotion(record);
      return record;
    }
  }

  /// 获取今日情绪记录
  Future<List<EmotionRecord>> getTodayEmotions() async {
    try {
      final response = await _dioClient.get(ApiConstants.todayEmotions);
      final data = response.data;

      if (data != null && data['records'] != null) {
        final records = (data['records'] as List)
            .map((r) => EmotionRecord.fromJson(r as Map<String, dynamic>))
            .toList();
        // 更新缓存
        await _cacheEmotions(records);
        return records;
      }
      return [];
    } catch (e) {
      debugPrint('获取今日情绪记录失败: $e，从缓存读取');
      return _getCachedEmotions();
    }
  }

  /// 缓存单条情绪记录
  Future<void> _cacheEmotion(EmotionRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = _getCachedEmotionsSync(prefs);
    existing.add(record);
    await _cacheEmotions(existing);
  }

  /// 缓存情绪记录列表
  Future<void> _cacheEmotions(List<EmotionRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(records.map((r) => r.toJson()).toList());
    await prefs.setString(_cacheKeyTodayEmotions, jsonStr);
  }

  /// 从缓存读取情绪记录
  List<EmotionRecord> _getCachedEmotions() {
    try {
      final prefs = SharedPreferences.getInstance();
      prefs.then((p) => _getCachedEmotionsSync(p));
      return [];
    } catch (_) {
      return [];
    }
  }

  /// 同步读取缓存
  List<EmotionRecord> _getCachedEmotionsSync(SharedPreferences prefs) {
    final jsonStr = prefs.getString(_cacheKeyTodayEmotions);
    if (jsonStr != null) {
      try {
        final list = jsonDecode(jsonStr) as List;
        return list
            .map((r) => EmotionRecord.fromJson(r as Map<String, dynamic>))
            .toList();
      } catch (_) {
        return [];
      }
    }
    return [];
  }
}
