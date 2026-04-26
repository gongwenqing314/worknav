/// 任务服务
/// 获取任务列表、提交步骤完成等
library;

import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/sync_service.dart';
import '../../core/utils/storage_util.dart';
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

  /// Web 平台 HTTP GET 请求辅助方法
  Future<Map<String, dynamic>?> _webGet(String path) async {
    final url = '${ApiConstants.baseUrl}$path';
    // 直接从 localStorage 读取最新 token（绕过 SharedPreferences 缓存）
    // SharedPreferences Web 版本会将值 JSON 编码存储
    final rawToken = html.window.localStorage['flutter.auth_token'];
    String? token;
    if (rawToken != null && rawToken.isNotEmpty) {
      try {
        token = (jsonDecode(rawToken) as String);
      } catch (_) {
        token = rawToken;
      }
    }
    final request = html.HttpRequest();
    request.open('GET', url, async: true);
    request.setRequestHeader('Content-Type', 'application/json');
    request.setRequestHeader('Accept', 'application/json');
    if (token != null && token.isNotEmpty) {
      request.setRequestHeader('Authorization', 'Bearer $token');
    }
    request.send(); // GET 请求也需要 send()
    await request.onLoad.first;
    if (request.status == 200) {
      return jsonDecode(request.responseText!) as Map<String, dynamic>;
    }
    throw Exception('Web request failed: ${request.status} ${request.statusText}');
  }

  /// Web 平台 HTTP POST 请求辅助方法
  Future<Map<String, dynamic>?> _webPost(String path, {dynamic data}) async {
    final url = '${ApiConstants.baseUrl}$path';
    final rawToken = html.window.localStorage['flutter.auth_token'];
    String? token;
    if (rawToken != null && rawToken.isNotEmpty) {
      try { token = (jsonDecode(rawToken) as String); } catch (_) { token = rawToken; }
    }
    final request = html.HttpRequest();
    request.open('POST', url, async: true);
    request.setRequestHeader('Content-Type', 'application/json');
    request.setRequestHeader('Accept', 'application/json');
    if (token != null && token.isNotEmpty) {
      request.setRequestHeader('Authorization', 'Bearer $token');
    }
    request.send(jsonEncode(data));
    await request.onLoad.first;
    if (request.status == 200 || request.status == 201) {
      if (request.responseText != null && request.responseText!.isNotEmpty) {
        return jsonDecode(request.responseText!) as Map<String, dynamic>;
      }
      return {};
    }
    throw Exception('Web request failed: ${request.status} ${request.statusText}');
  }

  /// 获取今日任务列表
  /// 优先从网络获取，失败时从本地缓存读取
  Future<List<TaskInstance>> getTodayTasks() async {
    try {
      List<dynamic>? taskList;

      if (kIsWeb) {
        final data = await _webGet(ApiConstants.todayTasks);
        if (data != null) {
          final inner = data['data'];
          if (inner is List) {
            taskList = inner;
          }
        }
      } else {
        final response = await _dioClient.get(ApiConstants.todayTasks);
        final data = response.data;

        // 后端返回 { code: 200, message: 'success', data: [...] }
        if (data is Map) {
          final inner = data['data'];
          if (inner is List) {
            taskList = inner;
          }
        } else if (data is List) {
          taskList = data;
        }
      }

      if (taskList != null) {
        final tasks = taskList
            .map((t) => TaskInstance.fromJson(t as Map<String, dynamic>))
            .toList();

        // 缓存到本地
        await _cacheTodayTasks(tasks);
        return tasks;
      }
      return [];
    } catch (e) {
      // 401 未授权错误向上传播（让上层重新登录）
      if (e.toString().contains('401')) {
        rethrow;
      }
      debugPrint('获取今日任务失败: $e，从缓存读取');
      return _getCachedTodayTasks();
    }
  }

  /// 获取任务详情（含步骤模板）
  Future<TaskTemplate?> getTaskDetail(String taskId) async {
    try {
      // 后端路径: /tasks/instances/:instanceId
      Map<String, dynamic>? inner;
      if (kIsWeb) {
        final data = await _webGet('/tasks/instances/$taskId');
        if (data != null) {
          inner = data['data'] as Map<String, dynamic>?;
        }
      } else {
        final response = await _dioClient.get('/tasks/instances/$taskId');
        final data = response.data;
        if (data != null) {
          inner = (data is Map ? data['data'] : data) as Map<String, dynamic>?;
        }
      }

      if (inner != null) {
        final template = TaskTemplate.fromJson(inner);
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
        path: '/tasks/steps/$stepId/complete',
        data: data,
      );
      return true;
    }

    try {
      // 后端路径: /tasks/steps/:executionId/complete
      if (kIsWeb) {
        await _webPost('/tasks/steps/$stepId/complete', data: data);
      } else {
        await _dioClient.post('/tasks/steps/$stepId/complete', data: data);
      }
      return true;
    } catch (e) {
      debugPrint('提交步骤完成失败: $e');
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
        path: '/tasks/steps/$stepId/complete',
        data: data,
      );
      return true;
    }
  }

  /// 提交任务完成
  Future<bool> completeTask(String taskId, {bool isOffline = false}) async {
    final data = {
      'completedAt': DateTime.now().toIso8601String(),
    };

    if (isOffline) {
      _syncService?.addPendingOperation(
        method: 'POST',
        path: '/tasks/instances/$taskId/complete',
        data: data,
      );
      return true;
    }

    try {
      // 后端路径: /tasks/instances/:instanceId/complete
      if (kIsWeb) {
        await _webPost('/tasks/instances/$taskId/complete', data: data);
      } else {
        await _dioClient.post('/tasks/instances/$taskId/complete', data: data);
      }
      return true;
    } catch (e) {
      debugPrint('提交任务完成失败: $e');
      _syncService?.addPendingOperation(
        method: 'POST',
        path: '/tasks/instances/$taskId/complete',
        data: data,
      );
      return true;
    }
  }

  /// 请求帮助
  Future<bool> requestHelp(String taskId) async {
    try {
      // 后端路径: /tasks/instances/:instanceId/help
      if (kIsWeb) {
        await _webPost('/tasks/instances/$taskId/help');
      } else {
        await _dioClient.post('/tasks/instances/$taskId/help');
      }
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
