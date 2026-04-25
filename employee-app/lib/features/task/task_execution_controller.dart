/// 任务执行状态管理
/// 管理任务执行过程中的步骤导航、完成状态等
library;

import 'package:flutter/material.dart';
import '../../../shared/models/task_instance.dart';
import '../../../shared/models/task_template.dart';
import '../../../shared/models/step_execution.dart';

/// 任务执行状态
enum TaskExecutionState {
  /// 加载中
  loading,
  /// 执行中
  executing,
  /// 已完成（展示庆祝动画）
  completed,
  /// 需要帮助
  needHelp,
  /// 错误
  error,
}

/// 任务执行控制器
class TaskExecutionController extends ChangeNotifier {
  /// 任务实例
  final TaskInstance task;

  /// 任务模板（含步骤定义）
  TaskTemplate? _template;
  TaskTemplate? get template => _template;

  /// 当前状态
  TaskExecutionState _state = TaskExecutionState.loading;
  TaskExecutionState get state => _state;

  /// 当前步骤索引（从0开始）
  int _currentStepIndex = 0;
  int get currentStepIndex => _currentStepIndex;

  /// 已完成的步骤索引集合
  final Set<int> _completedSteps = {};
  Set<int> get completedSteps => Set.unmodifiable(_completedSteps);

  /// 是否正在请求帮助
  bool _isRequestingHelp = false;
  bool get isRequestingHelp => _isRequestingHelp;

  /// 错误信息
  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  /// 是否显示庆祝动画
  bool get showCelebration => _state == TaskExecutionState.completed;

  TaskExecutionController({required this.task}) {
    _currentStepIndex = task.currentStepIndex;
    // 恢复已完成的步骤
    for (int i = 0; i < task.completedSteps; i++) {
      _completedSteps.add(i);
    }
  }

  /// 当前步骤数据
  TaskStep? get currentStep {
    if (_template == null) return null;
    if (_currentStepIndex < 0 || _currentStepIndex >= _template!.steps.length) {
      return null;
    }
    return _template!.steps[_currentStepIndex];
  }

  /// 步骤总数
  int get totalSteps => _template?.steps.length ?? task.totalSteps;

  /// 是否为第一步
  bool get isFirstStep => _currentStepIndex == 0;

  /// 是否为最后一步
  bool get isLastStep => _currentStepIndex >= totalSteps - 1;

  /// 当前步骤是否已完成（回看模式）
  bool get isCurrentStepCompleted => _completedSteps.contains(_currentStepIndex);

  /// 加载任务详情
  Future<void> loadTaskDetail() async {
    _state = TaskExecutionState.loading;
    notifyListeners();

    try {
      // 模拟加载任务模板
      await Future.delayed(const Duration(milliseconds: 800));
      _template = _getMockTemplate();

      _state = TaskExecutionState.executing;
    } catch (e) {
      _errorMessage = '加载任务详情失败';
      _state = TaskExecutionState.error;
    }

    notifyListeners();
  }

  /// 完成当前步骤
  void completeCurrentStep() {
    if (_state != TaskExecutionState.executing) return;

    // 标记当前步骤为已完成
    _completedSteps.add(_currentStepIndex);

    // 检查是否所有步骤都已完成
    if (_completedSteps.length >= totalSteps) {
      _state = TaskExecutionState.completed;
      notifyListeners();
      return;
    }

    // 前进到下一个未完成的步骤
    _currentStepIndex++;
    // 跳过已完成的步骤（如果有的话）
    while (_completedSteps.contains(_currentStepIndex) &&
        _currentStepIndex < totalSteps) {
      _currentStepIndex++;
    }

    notifyListeners();
  }

  /// 返回上一步
  void goToPreviousStep() {
    if (_currentStepIndex > 0) {
      _currentStepIndex--;
      notifyListeners();
    }
  }

  /// 跳转到指定步骤
  void goToStep(int index) {
    if (index >= 0 && index < totalSteps) {
      _currentStepIndex = index;
      notifyListeners();
    }
  }

  /// 请求帮助
  Future<void> requestHelp() async {
    _isRequestingHelp = true;
    notifyListeners();

    try {
      // 模拟请求帮助
      await Future.delayed(const Duration(seconds: 1));
      _state = TaskExecutionState.needHelp;
    } catch (e) {
      _errorMessage = '请求帮助失败';
    }

    _isRequestingHelp = false;
    notifyListeners();
  }

  /// 关闭庆祝动画，返回主页
  void dismissCelebration() {
    _state = TaskExecutionState.completed;
    notifyListeners();
  }

  /// 模拟任务模板数据
  TaskTemplate _getMockTemplate() {
    final steps = <TaskStep>[
      TaskStep(
        order: 1,
        id: 'step_1',
        title: '准备工作',
        instruction: '找到清洁工具：抹布、水桶、清洁剂。将抹布浸湿后拧干。',
        imageUrl: '',
        audioUrl: '',
      ),
      TaskStep(
        order: 2,
        id: 'step_2',
        title: '擦拭桌面',
        instruction: '用湿抹布从左到右擦拭桌面，确保每个角落都擦到。',
        imageUrl: '',
        audioUrl: '',
      ),
      TaskStep(
        order: 3,
        id: 'step_3',
        title: '清理污渍',
        instruction: '如果桌面上有顽固污渍，喷少量清洁剂，用抹布反复擦拭。',
        imageUrl: '',
        audioUrl: '',
      ),
      TaskStep(
        order: 4,
        id: 'step_4',
        title: '检查桌面',
        instruction: '仔细检查桌面是否干净整洁，没有遗漏的污渍和水渍。',
        imageUrl: '',
        audioUrl: '',
      ),
      TaskStep(
        order: 5,
        id: 'step_5',
        title: '收好工具',
        instruction: '将抹布清洗后晾干，清洁剂放回原处。工作完成！',
        imageUrl: '',
        audioUrl: '',
      ),
    ];

    return TaskTemplate(
      id: task.templateId,
      name: task.name,
      description: task.description,
      iconUrl: task.iconUrl,
      iconColor: task.iconColor,
      steps: steps,
      estimatedMinutes: 30,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
