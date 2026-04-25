/**
 * 通知路由
 */
const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notification.controller');
const { authMiddleware } = require('../middlewares/auth.middleware');
const { validate } = require('../middlewares/validator.middleware');
const { body } = require('express-validator');

// 所有通知路由都需要认证
router.use(authMiddleware);

/**
 * 获取通知列表
 * GET /api/v1/notifications
 */
router.get('/', notificationController.list);

/**
 * 获取未读通知数量
 * GET /api/v1/notifications/unread-count
 */
router.get('/unread-count', notificationController.getUnreadCount);

/**
 * 全部标记为已读
 * PUT /api/v1/notifications/read-all
 */
router.put('/read-all', notificationController.markAllAsRead);

/**
 * 发送语音加油
 * POST /api/v1/notifications/voice-cheer
 */
router.post(
  '/voice-cheer',
  [
    body('toUserId').isInt().withMessage('接收用户ID无效'),
    validate,
  ],
  notificationController.sendVoiceCheer
);

/**
 * 标记通知为已读
 * PUT /api/v1/notifications/:notificationId/read
 */
router.put('/:notificationId/read', notificationController.markAsRead);

/**
 * 删除通知
 * DELETE /api/v1/notifications/:notificationId
 */
router.delete('/:notificationId', notificationController.delete);

module.exports = router;
