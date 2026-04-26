/// 主页状态管理
/// 使用 ChangeNotifier 管理主页数据和状态
library;

import 'package:flutter/material.dart';
import '../../../shared/models/task_instance.dart';
import '../../../shared/services/task_service.dart';
import '../../../shared/services/auth_service.dart';

/// 主页状态
enum HomeState {
  /// 加载中
  loading,
  /// 数据就绪
  ready,
  /// 加载失败
  error,
  /// 空状态（无任务）
  empty,
}

/// 主页控制器
class HomeController extends ChangeNotifier {
  final TaskService _taskService;
  final AuthService _authService;

  HomeController(this._taskService, this._authService);

  /// 当前状态
  HomeState _state = HomeState.loading;
  HomeState get state => _state;

  /// 今日任务列表
  List<TaskInstance> _tasks = [];
  List<TaskInstance> get tasks => _tasks;

  /// 错误信息
  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  /// 同步状态
  String _syncStatus = '已同步';
  String get syncStatus => _syncStatus;

  /// 员工姓名
  String _employeeName = '';
  String get employeeName => _employeeName;

  /// 当前选中的底部导航索引
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  /// 更新底部导航索引
  void updateCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  /// 加载今日任务
  Future<void> loadTasks() async {
    _state = HomeState.loading;
    notifyListeners();

    try {
      // 获取员工姓名
      _employeeName = _authService.getEmployeeName() ?? '';
      debugPrint('HomeController: 开始加载任务, 员工=$_employeeName');

      // 调用后端获取今日任务
      var tasks = await _taskService.getTodayTasks();
      debugPrint('HomeController: 获取到 ${tasks.length} 条任务');
      _tasks = tasks;
      _syncStatus = '已同步';
      _state = _tasks.isEmpty ? HomeState.empty : HomeState.ready;
    } catch (e, stack) {
      debugPrint('HomeController: 加载任务失败: $e');

      // 如果是 401 错误，尝试重新登录后重试
      if (e.toString().contains('401')) {
        debugPrint('HomeController: 401 错误，尝试重新登录');
        final loggedIn = await _authService.deviceLogin();
        if (loggedIn) {
          _employeeName = _authService.getEmployeeName() ?? '';
          try {
            final tasks = await _taskService.getTodayTasks();
            debugPrint('HomeController: 重新登录后获取到 ${tasks.length} 条任务');
            _tasks = tasks;
            _syncStatus = '已同步';
            _state = _tasks.isEmpty ? HomeState.empty : HomeState.ready;
            notifyListeners();
            return;
          } catch (e2) {
            debugPrint('HomeController: 重新登录后仍然失败: $e2');
          }
        }
      }

      _errorMessage = '加载任务失败，请检查网络连接';
      _state = HomeState.error;
    }

    notifyListeners();
  }

  /// 重试加载
  Future<void> retry() async {
    await loadTasks();
  }

  /// 更新同步状态
  void updateSyncStatus(String status) {
    _syncStatus = status;
    notifyListeners();
  }

  /// 获取待执行任务数量
  int get pendingCount =>
      _tasks.where((t) => t.status == TaskStatus.pending).length;

  /// 获取进行中任务数量
  int get inProgressCount =>
      _tasks.where((t) => t.status == TaskStatus.inProgress).length;

  /// 获取已完成任务数量
  int get completedCount =>
      _tasks.where((t) => t.status == TaskStatus.completed).length;
}
