/**
 * 数据统计路由
 */
const express = require('express');
const router = express.Router();
const statisticsController = require('../controllers/statistics.controller');
const { authMiddleware } = require('../middlewares/auth.middleware');
const { isCounselor } = require('../middlewares/rbac.middleware');
const { validate } = require('../middlewares/validator.middleware');
const { query } = require('express-validator');

// 所有统计路由都需要认证
router.use(authMiddleware);

/**
 * 获取任务完成率统计
 * GET /api/v1/statistics/task-completion
 */
router.get(
  '/task-completion',
  [
    query('range').optional().isIn(['today', 'week', 'month']).withMessage('无效的时间范围'),
    validate,
  ],
  statisticsController.taskCompletion
);

/**
 * 获取步骤耗时分析（卡顿热点）
 * GET /api/v1/statistics/step-duration
 */
router.get(
  '/step-duration',
  [
    query('templateId').isInt().withMessage('模板ID无效'),
    query('range').optional().isIn(['today', 'week', 'month']).withMessage('无效的时间范围'),
    validate,
  ],
  statisticsController.stepDuration
);

/**
 * 获取员工工作概览
 * GET /api/v1/statistics/employee-overview
 */
router.get(
  '/employee-overview',
  [
    query('employeeId').isInt().withMessage('员工ID无效'),
    validate,
  ],
  statisticsController.employeeOverview
);

/**
 * 获取系统概览（辅导员仪表盘）
 * GET /api/v1/statistics/dashboard
 */
router.get('/dashboard', isCounselor, statisticsController.dashboard);

/**
 * 获取情绪统计数据
 * GET /api/v1/statistics/emotion
 */
router.get('/emotion', isCounselor, statisticsController.emotion);

/**
 * 获取员工工作统计
 * GET /api/v1/statistics/employee-work
 */
router.get('/employee-work', isCounselor, statisticsController.employeeWork);

module.exports = router;
