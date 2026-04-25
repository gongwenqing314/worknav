/// 任务服务
/// 获取任务列表、提交步骤完成等
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/sync_service.dart';
import '../models/task_instance.dart';
import '../models/task_template.dart';
import '../models/step_execution.dart';

/// 任务服务
class TaskService {
  final DioClient _dioClient;
  final SyncService? _syncService;

  TaskService(this._dioClient, {SyncService? syncService})
      : _syncService = syncService;

  // ===== 本地缓存键 =====
  static const String _cacheKeyTodayTasks = 'cache_today_tasks';
  static const String _cacheKeyTaskTemplates = 'cache_task_templates';
  static const String _cacheKeyStepExecutions = 'cache_step_executions_';

  /// 获取今日任务列表
  /// 优先从网络获取，失败时从本地缓存读取
  Future<List<TaskInstance>> getTodayTasks() async {
    try {
      final response = await _dioClient.get(ApiConstants.todayTasks);
      final data = response.data;

      if (data != null && data['tasks'] != null) {
        final tasks = (data['tasks'] as List)
            .map((t) => TaskInstance.fromJson(t as Map<String, dynamic>))
            .toList();

        // 缓存到本地
        await _cacheTodayTasks(tasks);
        return tasks;
      }
      return [];
    } catch (e) {
      debugPrint('获取今日任务失败: $e，从缓存读取');
      return _getCachedTodayTasks();
    }
  }

  /// 获取任务详情（含步骤模板）
  Future<TaskTemplate?> getTaskDetail(String taskId) async {
    try {
      final response = await _dioClient.get('${ApiConstants.taskDetail}$taskId');
      final data = response.data;

      if (data != null) {
        final template = TaskTemplate.fromJson(data);
        // 缓存模板
        await _cacheTaskTemplate(taskId, template);
        return template;
      }
      return null;
    } catch (e) {
      debugPrint('获取任务详情失败: $e，从缓存读取');
      return _getCachedTaskTemplate(taskId);
    }
  }

  /// 提交步骤完成
  Future<bool> completeStep({
    required String taskId,
    required String stepId,
    required int stepOrder,
    bool isOffline = false,
  }) async {
    final data = {
      'taskId': taskId,
      'stepId': stepId,
      'stepOrder': stepOrder,
      'completedAt': DateTime.now().toIso8601String(),
    };

    if (isOffline) {
      // 离线模式：缓存操作，等待联网同步
      await _cacheStepExecution(StepExecution(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        taskInstanceId: taskId,
        stepId: stepId,
        stepOrder: stepOrder,
        title: '',
        instruction: '',
        status: StepExecutionStatus.completed,
        completedTime: DateTime.now(),
      ));

      // 添加到同步队列
      _syncService?.addPendingOperation(
        method: 'POST',
        path: ApiConstants.completeStep
            .replaceAll('{taskId}', taskId)
            .replaceAll('{stepId}', stepId),
        data: data,
      );
      return true;
    }

    try {
      final path = ApiConstants.completeStep
          .replaceAll('{taskId}', taskId)
          .replaceAll('{stepId}', stepId);
      await _dioClient.post(path, data: data);
      return true;
    } catch (e) {
      debugPrint('提交步骤完成失败: $e');
      // 网络失败，缓存操作
      await _cacheStepExecution(StepExecution(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        taskInstanceId: taskId,
        stepId: stepId,
        stepOrder: stepOrder,
        title: '',
        instruction: '',
        status: StepExecutionStatus.completed,
        completedTime: DateTime.now(),
      ));
      _syncService?.addPendingOperation(
        method: 'POST',
        path: ApiConstants.completeStep
            .replaceAll('{taskId}', taskId)
            .replaceAll('{stepId}', stepId),
        data: data,
      );
      return true; // 本地操作成功
    }
  }

  /// 提交任务完成
  Future<bool> completeTask(String taskId, {bool isOffline = false}) async {
    final data = {
      'taskId': taskId,
      'completedAt': DateTime.now().toIso8601String(),
    };

    if (isOffline) {
      _syncService?.addPendingOperation(
        method: 'POST',
        path: ApiConstants.completeTask.replaceAll('{taskId}', taskId),
        data: data,
      );
      return true;
    }

    try {
      await _dioClient.post(
        ApiConstants.completeTask.replaceAll('{taskId}', taskId),
        data: data,
      );
      return true;
    } catch (e) {
      debugPrint('提交任务完成失败: $e');
      _syncService?.addPendingOperation(
        method: 'POST',
        path: ApiConstants.completeTask.replaceAll('{taskId}', taskId),
        data: data,
      );
      return true;
    }
  }

  /// 请求帮助
  Future<bool> requestHelp(String taskId) async {
    try {
      await _dioClient.post(
        ApiConstants.requestHelp.replaceAll('{taskId}', taskId),
      );
      return true;
    } catch (e) {
      debugPrint('请求帮助失败: $e');
      return false;
    }
  }

  // ===== 本地缓存方法 =====

  Future<void> _cacheTodayTasks(List<TaskInstance> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(tasks.map((t) => t.toJson()).toList());
    await prefs.setString(_cacheKeyTodayTasks, jsonStr);
  }

  List<TaskInstance> _getCachedTodayTasks() {
    try {
      final prefs = SharedPreferences.getInstance();
      prefs.then((p) {
        final jsonStr = p.getString(_cacheKeyTodayTasks);
        if (jsonStr != null) {
          final list = jsonDecode(jsonStr) as List;
          return list
              .map((t) => TaskInstance.fromJson(t as Map<String, dynamic>))
              .toList();
        }
        return <TaskInstance>[];
      });
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<void> _cacheTaskTemplate(String taskId, TaskTemplate template) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(template.toJson());
    await prefs.setString('$_cacheKeyTaskTemplates$taskId', jsonStr);
  }

  Future<TaskTemplate?> _getCachedTaskTemplate(String taskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('$_cacheKeyTaskTemplates$taskId');
      if (jsonStr != null) {
        return TaskTemplate.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheStepExecution(StepExecution execution) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_cacheKeyStepExecutions${execution.taskInstanceId}';
    final existing = prefs.getStringList(key) ?? [];
    existing.add(jsonEncode(execution.toJson()));
    await prefs.setStringList(key, existing);
  }
}
