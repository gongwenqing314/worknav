/**
 * 任务管理路由
 */
const express = require('express');
const router = express.Router();
const taskController = require('../controllers/task.controller');
const { authMiddleware } = require('../middlewares/auth.middleware');
const { allowRoles, isCounselor } = require('../middlewares/rbac.middleware');
const { validate } = require('../middlewares/validator.middleware');
const { body, param } = require('express-validator');

// 所有任务路由都需要认证
router.use(authMiddleware);

// ========== 任务模板管理 ==========

/**
 * 获取任务模板列表
 * GET /api/v1/tasks/templates
 */
router.get('/templates', taskController.listTemplates);

/**
 * 获取任务模板详情
 * GET /api/v1/tasks/templates/:templateId
 */
router.get('/templates/:templateId', taskController.getTemplate);

/**
 * 创建任务模板
 * POST /api/v1/tasks/templates
 * 仅辅导员和协管员可创建
 */
router.post(
  '/templates',
  isCounselor,
  [
    body('title').trim().notEmpty().withMessage('模板标题不能为空'),
    validate,
  ],
  taskController.createTemplate
);

/**
 * 更新任务模板
 * PUT /api/v1/tasks/templates/:templateId
 */
router.put(
  '/templates/:templateId',
  isCounselor,
  taskController.updateTemplate
);

/**
 * 删除任务模板
 * DELETE /api/v1/tasks/templates/:templateId
 */
router.delete('/templates/:templateId', isCounselor, taskController.deleteTemplate);

// ========== 任务实例管理 ==========

/**
 * 获取今日任务（员工端）
 * GET /api/v1/tasks/today
 */
router.get('/today', allowRoles('employee'), taskController.todayTasks);

/**
 * 获取任务实例列表
 * GET /api/v1/tasks/instances
 */
router.get('/instances', taskController.listInstances);

/**
 * 获取任务实例详情
 * GET /api/v1/tasks/instances/:instanceId
 */
router.get('/instances/:instanceId', taskController.getInstance);

/**
 * 更新任务实例
 * PUT /api/v1/tasks/instances/:instanceId
 */
router.put('/instances/:instanceId', isCounselor, taskController.updateInstance);

/**
 * 删除任务实例
 * DELETE /api/v1/tasks/instances/:instanceId
 */
router.delete('/instances/:instanceId', isCounselor, taskController.deleteInstance);

/**
 * 分配任务
 * POST /api/v1/tasks/instances/assign
 * 仅辅导员和协管员可分配
 */
router.post(
  '/instances/assign',
  isCounselor,
  [
    body('templateId').isInt().withMessage('模板ID无效'),
    body('employeeId').isInt().withMessage('员工ID无效'),
    validate,
  ],
  taskController.assignTask
);

/**
 * 创建任务实例
 * POST /api/v1/tasks/instances
 */
router.post('/instances', authMiddleware, isCounselor, taskController.createInstance);

/**
 * 开始执行任务
 * POST /api/v1/tasks/instances/:instanceId/start
 */
router.post('/instances/:instanceId/start', allowRoles('employee'), taskController.startTask);

/**
 * 暂停任务
 * POST /api/v1/tasks/instances/:instanceId/pause
 */
router.post('/instances/:instanceId/pause', allowRoles('employee'), taskController.pauseTask);

/**
 * 取消任务
 * POST /api/v1/tasks/instances/:instanceId/cancel', taskController.cancelTask
 */
router.post('/instances/:instanceId/cancel', taskController.cancelTask);

/**
 * 完成任务（员工端）
 * POST /api/v1/tasks/instances/:instanceId/complete
 */
router.post('/instances/:instanceId/complete', allowRoles('employee'), taskController.completeTask);

/**
 * 请求帮助（员工端）
 * POST /api/v1/tasks/instances/:instanceId/help
 */
router.post('/instances/:instanceId/help', allowRoles('employee'), taskController.requestHelp);

// ========== 步骤执行管理 ==========

/**
 * 开始执行步骤
 * POST /api/v1/tasks/steps/:executionId/start
 */
router.post('/steps/:executionId/start', allowRoles('employee'), taskController.startStep);

/**
 * 完成步骤
 * POST /api/v1/tasks/steps/:executionId/complete
 */
router.post(
  '/steps/:executionId/complete',
  allowRoles('employee'),
  taskController.completeStep
);

// ========== 任务监控 ==========

/**
 * 获取任务执行记录（监控页面用）
 * GET /api/v1/tasks/:taskId/executions
 */
router.get('/:taskId/executions', taskController.getExecutions);

module.exports = router;
