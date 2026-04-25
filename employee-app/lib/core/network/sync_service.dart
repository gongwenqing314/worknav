/// 离线同步服务
/// 管理离线数据缓存和联网后的自动同步
library;

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dio_client.dart';
import '../constants/api_constants.dart';

/// 同步状态
enum SyncStatus {
  /// 已同步
  synced,
  /// 同步中
  syncing,
  /// 离线模式
  offline,
  /// 同步失败
  error,
}

class SyncService {
  final DioClient _dioClient;
  final Connectivity _connectivity;

  /// 同步状态变化回调
  final void Function(SyncStatus status)? onStatusChanged;

  /// 当前同步状态
  SyncStatus _status = SyncStatus.synced;
  SyncStatus get status => _status;

  /// 待同步的操作队列（离线时暂存）
  final List<Map<String, dynamic>> _pendingOperations = [];

  /// 网络状态监听订阅
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  SyncService({
    required DioClient dioClient,
    Connectivity? connectivity,
    this.onStatusChanged,
  })  : _dioClient = dioClient,
        _connectivity = connectivity ?? Connectivity();

  /// 初始化同步服务，开始监听网络状态
  Future<void> init() async {
    // 检查初始网络状态
    final results = await _connectivity.checkConnectivity();
    _handleConnectivityChange(results);

    // 监听网络状态变化
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
    );
  }

  /// 处理网络状态变化
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final hasConnection = results.isNotEmpty &&
        !results.contains(ConnectivityResult.none);

    if (hasConnection) {
      _updateStatus(SyncStatus.synced);
      // 网络恢复，自动同步离线数据
      _syncPendingOperations();
    } else {
      _updateStatus(SyncStatus.offline);
    }
  }

  /// 更新同步状态并通知
  void _updateStatus(SyncStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      onStatusChanged?.call(_status);
    }
  }

  /// 添加待同步操作（离线时调用）
  /// [method] HTTP 方法: GET, POST, PUT, DELETE
  /// [path] API 路径
  /// [data] 请求数据
  Future<void> addPendingOperation({
    required String method,
    required String path,
    Map<String, dynamic>? data,
  }) async {
    final operation = {
      'method': method,
      'path': path,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _pendingOperations.add(operation);

    // 持久化到本地存储
    final prefs = await SharedPreferences.getInstance();
    final pendingJson = _pendingOperations
        .map((op) => op.toString())
        .toList();
    await prefs.setStringList('pending_operations', pendingJson);

    // 如果当前有网络，立即同步
    if (_status == SyncStatus.synced) {
      await _syncPendingOperations();
    }
  }

  /// 同步所有待处理操作
  Future<void> _syncPendingOperations() async {
    if (_pendingOperations.isEmpty) return;

    _updateStatus(SyncStatus.syncing);

    // 复制待处理列表，清空原列表
    final operations = List<Map<String, dynamic>>.from(_pendingOperations);
    _pendingOperations.clear();

    for (final operation in operations) {
      try {
        final method = operation['method'] as String;
        final path = operation['path'] as String;
        final data = operation['data'] as Map<String, dynamic>?;

        switch (method.toUpperCase()) {
          case 'POST':
            await _dioClient.post(path, data: data);
            break;
          case 'PUT':
            await _dioClient.put(path, data: data);
            break;
          case 'DELETE':
            await _dioClient.delete(path, data: data);
            break;
          default:
            // GET 请求不需要离线同步
            break;
        }
      } catch (e) {
        // 同步失败，放回队列
        _pendingOperations.add(operation);
        _updateStatus(SyncStatus.error);
        return;
      }
    }

    // 同步完成，清除本地持久化
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_operations');
    _updateStatus(SyncStatus.synced);
  }

  /// 手动触发同步
  Future<void> syncNow() async {
    if (_status == SyncStatus.offline) {
      // 离线模式下无法同步
      return;
    }
    await _syncPendingOperations();
  }

  /// 释放资源
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
