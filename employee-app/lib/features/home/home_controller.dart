/// 主页状态管理
/// 使用 ChangeNotifier 管理主页数据和状态
library;

import 'package:flutter/material.dart';
import '../../../shared/models/task_instance.dart';

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
      // 模拟网络请求
      // 实际项目中调用 TaskService.getTodayTasks()
      await Future.delayed(const Duration(seconds: 1));

      // 模拟数据
      _tasks = _getMockTasks();
      _employeeName = '小明';
      _state = _tasks.isEmpty ? HomeState.empty : HomeState.ready;
    } catch (e) {
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

  /// 模拟任务数据
  List<TaskInstance> _getMockTasks() {
    final now = DateTime.now();
    return [
      TaskInstance(
        id: 'task_1',
        templateId: 'tpl_1',
        name: '整理货架',
        description: '将商品按类别摆放到对应货架上',
        iconUrl: '',
        iconColor: '#4CAF50',
        status: TaskStatus.inProgress,
        totalSteps: 5,
        completedSteps: 2,
        currentStepIndex: 2,
        scheduledTime: DateTime(now.year, now.month, now.day, 9, 0),
        startTime: DateTime(now.year, now.month, now.day, 9, 5),
        assignedBy: 'admin_1',
      ),
      TaskInstance(
        id: 'task_2',
        templateId: 'tpl_2',
        name: '清洁桌面',
        description: '用抹布擦拭所有工作台面',
        iconUrl: '',
        iconColor: '#2196F3',
        status: TaskStatus.pending,
        totalSteps: 3,
        completedSteps: 0,
        currentStepIndex: 0,
        scheduledTime: DateTime(now.year, now.month, now.day, 10, 30),
        assignedBy: 'admin_1',
      ),
      TaskInstance(
        id: 'task_3',
        templateId: 'tpl_3',
        name: '包装商品',
        description: '将商品装入包装盒并贴上标签',
        iconUrl: '',
        iconColor: '#FF9800',
        status: TaskStatus.pending,
        totalSteps: 4,
        completedSteps: 0,
        currentStepIndex: 0,
        scheduledTime: DateTime(now.year, now.month, now.day, 14, 0),
        assignedBy: 'admin_2',
      ),
      TaskInstance(
        id: 'task_4',
        templateId: 'tpl_4',
        name: '清点库存',
        description: '清点指定区域的商品数量',
        iconUrl: '',
        iconColor: '#9C27B0',
        status: TaskStatus.completed,
        totalSteps: 6,
        completedSteps: 6,
        currentStepIndex: 6,
        scheduledTime: DateTime(now.year, now.month, now.day, 8, 0),
        startTime: DateTime(now.year, now.month, now.day, 8, 0),
        completedTime: DateTime(now.year, now.month, now.day, 8, 45),
        assignedBy: 'admin_1',
      ),
    ];
  }
}
