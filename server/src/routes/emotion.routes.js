/**
 * 情绪记录路由
 */
const express = require('express');
const router = express.Router();
const emotionController = require('../controllers/emotion.controller');
const { authMiddleware } = require('../middlewares/auth.middleware');
const { isCounselor, canAccessEmployee, allowRoles } = require('../middlewares/rbac.middleware');
const { validate } = require('../middlewares/validator.middleware');
const { body, param } = require('express-validator');

// 所有情绪路由都需要认证
router.use(authMiddleware);

/**
 * 记录情绪
 * POST /api/v1/emotions/record
 * 员工记录自己的情绪
 */
router.post(
  '/record',
  allowRoles('employee'),
  [
    body('emotionType').isIn(['happy', 'calm', 'anxious', 'sad', 'angry', 'confused']).withMessage('无效的情绪类型'),
    body('intensity').isInt({ min: 1, max: 5 }).withMessage('情绪强度范围1-5'),
    validate,
  ],
  (req, res, next) => {
    // 将当前用户ID设为路径参数
    req.params.employeeId = req.user.id;
    emotionController.record(req, res, next);
  }
);

/**
 * 记录情绪（辅导员代记录）
 * POST /api/v1/emotions/:employeeId
 */
router.post(
  '/:employeeId',
  isCounselor,
  [
    body('emotionType').isIn(['happy', 'calm', 'anxious', 'sad', 'angry', 'confused']).withMessage('无效的情绪类型'),
    body('intensity').isInt({ min: 1, max: 5 }).withMessage('情绪强度范围1-5'),
    validate,
  ],
  emotionController.record
);

/**
 * 获取情绪记录列表
 * GET /api/v1/emotions/:employeeId
 */
router.get('/:employeeId', canAccessEmployee('employeeId'), emotionController.list);

/**
 * 获取情绪统计
 * GET /api/v1/emotions/:employeeId/stats
 */
router.get('/:employeeId/stats', canAccessEmployee('employeeId'), emotionController.getStats);

// ========== 情绪预警规则管理（仅辅导员） ==========

/**
 * 获取预警规则列表
 * GET /api/v1/emotions/alert-rules
 */
router.get('/alert-rules/list', isCounselor, emotionController.listAlertRules);

/**
 * 创建预警规则
 * POST /api/v1/emotions/alert-rules
 */
router.post(
  '/alert-rules',
  isCounselor,
  [
    body('negativeTypes').isArray({ min: 1 }).withMessage('消极情绪类型不能为空'),
    body('consecutiveDays').isInt({ min: 1 }).withMessage('连续天数至少为1'),
    body('minIntensity').isInt({ min: 1, max: 5 }).withMessage('最低强度范围1-5'),
    validate,
  ],
  emotionController.createAlertRule
);

/**
 * 更新预警规则
 * PUT /api/v1/emotions/alert-rules/:ruleId
 */
router.put('/alert-rules/:ruleId', isCounselor, emotionController.updateAlertRule);

/**
 * 删除预警规则
 * DELETE /api/v1/emotions/alert-rules/:ruleId
 */
router.delete('/alert-rules/:ruleId', isCounselor, emotionController.deleteAlertRule);


module.exports = router;
