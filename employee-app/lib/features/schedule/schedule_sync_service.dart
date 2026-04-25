/// 排班同步服务
/// 定期同步排班信息，更新本地任务列表
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';

/// 排班同步服务
/// 定期从服务器同步排班信息，确保本地任务列表是最新的
class ScheduleSyncService {
  final DioClient _dioClient;

  /// 同步间隔（分钟）
  final int syncIntervalMinutes;

  /// 定时器
  Timer? _syncTimer;

  /// 上次同步时间
  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// 同步状态回调
  final void Function(bool success, String message)? onSyncComplete;

  /// 是否正在同步
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  ScheduleSyncService({
    required DioClient dioClient,
    this.syncIntervalMinutes = 30,
    this.onSyncComplete,
  }) : _dioClient = dioClient;

  /// 启动定时同步
  void startPeriodicSync() {
    stopPeriodicSync();

    _syncTimer = Timer.periodic(
      Duration(minutes: syncIntervalMinutes),
      (_) => syncNow(),
    );

    debugPrint('排班同步已启动，间隔 $syncIntervalMinutes 分钟');
  }

  /// 停止定时同步
  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// 立即同步
  Future<bool> syncNow() async {
    if (_isSyncing) return false;

    _isSyncing = true;

    try {
      final response = await _dioClient.post(ApiConstants.syncSchedule);
      final data = response.data;

      if (data != null && data['success'] == true) {
        _lastSyncTime = DateTime.now();
        _isSyncing = false;
        onSyncComplete?.call(true, '同步成功');
        debugPrint('排班同步成功: ${_lastSyncTime.toString()}');
        return true;
      }

      _isSyncing = false;
      onSyncComplete?.call(false, '同步失败：服务器返回错误');
      return false;
    } catch (e) {
      _isSyncing = false;
      onSyncComplete?.call(false, '同步失败：$e');
      debugPrint('排班同步失败: $e');
      return false;
    }
  }

  /// 释放资源
  void dispose() {
    stopPeriodicSync();
  }
}
