/**
 * 排班路由
 */
const express = require('express');
const router = express.Router();
const scheduleController = require('../controllers/schedule.controller');
const { authMiddleware } = require('../middlewares/auth.middleware');
const { isCounselor } = require('../middlewares/rbac.middleware');
const { validate } = require('../middlewares/validator.middleware');
const { body, query } = require('express-validator');

// 所有排班路由都需要认证
router.use(authMiddleware);

/**
 * 获取某日的排班任务列表
 * GET /api/v1/schedules?date=2024-01-01
 */
router.get(
  '/',
  [
    query('date').isISO8601().withMessage('日期格式不正确'),
    validate,
  ],
  scheduleController.getDailySchedule
);

/**
 * 获取一周排班概览
 * GET /api/v1/schedules/week?startDate=2024-01-01
 */
router.get(
  '/week',
  [
    query('startDate').isISO8601().withMessage('起始日期格式不正确'),
    validate,
  ],
  scheduleController.getWeekSchedule
);

/**
 * 批量排班
 * POST /api/v1/schedules/batch
 * 仅辅导员和协管员可操作
 */
router.post(
  '/batch',
  isCounselor,
  [
    body('schedules').isArray({ min: 1 }).withMessage('排班数据不能为空'),
    body('schedules.*.templateId').isInt().withMessage('模板ID无效'),
    body('schedules.*.employeeId').isInt().withMessage('员工ID无效'),
    body('schedules.*.scheduledDate').isISO8601().withMessage('排班日期格式不正确'),
    validate,
  ],
  scheduleController.batchSchedule
);

module.exports = router;
