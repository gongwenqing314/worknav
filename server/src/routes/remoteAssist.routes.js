/**
 * 远程协助路由
 */
const express = require('express');
const router = express.Router();
const remoteAssistController = require('../controllers/remoteAssist.controller');
const { authMiddleware } = require('../middlewares/auth.middleware');
const { isCounselor, allowRoles } = require('../middlewares/rbac.middleware');
const { validate } = require('../middlewares/validator.middleware');
const { body } = require('express-validator');

// 所有远程协助路由都需要认证
router.use(authMiddleware);

/**
 * 创建协助请求（员工）
 * POST /api/v1/remote-assist/sessions
 */
router.post(
  '/sessions',
  allowRoles('employee'),
  remoteAssistController.uploadMiddleware,
  remoteAssistController.createSession
);

/**
 * 获取待接听的协助请求列表（辅导员）
 * GET /api/v1/remote-assist/sessions/pending
 */
router.get('/sessions/pending', isCounselor, remoteAssistController.listPendingSessions);

/**
 * 获取协助会话列表
 * GET /api/v1/remote-assist/sessions
 */
router.get('/sessions', remoteAssistController.listSessions);

/**
 * 获取会话详情（含消息历史）
 * GET /api/v1/remote-assist/sessions/:sessionId
 */
router.get('/sessions/:sessionId', remoteAssistController.getSession);

/**
 * 接听协助请求（辅导员）
 * POST /api/v1/remote-assist/sessions/:sessionId/accept
 */
router.post('/sessions/:sessionId/accept', isCounselor, remoteAssistController.acceptSession);

/**
 * 发送消息
 * POST /api/v1/remote-assist/sessions/:sessionId/messages
 */
router.post(
  '/sessions/:sessionId/messages',
  remoteAssistController.messageUploadMiddleware,
  remoteAssistController.sendMessage
);

/**
 * 获取会话消息历史
 * GET /api/v1/remote-assist/sessions/:sessionId/messages
 */
router.get('/sessions/:sessionId/messages', remoteAssistController.getMessages);

/**
 * 上传标注图片（辅导员）
 * POST /api/v1/remote-assist/sessions/:sessionId/annotation
 */
router.post(
  '/sessions/:sessionId/annotation',
  isCounselor,
  remoteAssistController.annotationUploadMiddleware,
  remoteAssistController.uploadAnnotation
);

/**
 * 结束协助会话
 * POST /api/v1/remote-assist/sessions/:sessionId/end
 */
router.post(
  '/sessions/:sessionId/end',
  [
    body('rating').optional().isInt({ min: 1, max: 5 }).withMessage('评分范围1-5'),
    validate,
  ],
  remoteAssistController.endSession
);

module.exports = router;
