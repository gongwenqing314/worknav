/**
 * 设备管理路由
 */
const express = require('express');
const router = express.Router();
const deviceController = require('../controllers/device.controller');
const { authMiddleware } = require('../middlewares/auth.middleware');
const { validate } = require('../middlewares/validator.middleware');
const { body } = require('express-validator');

// 所有设备路由都需要认证
router.use(authMiddleware);

/**
 * 生成绑定码
 * POST /api/v1/devices/bind-code
 */
router.post('/bind-code', deviceController.generateBindCode);

/**
 * 使用绑定码绑定设备
 * POST /api/v1/devices/bind
 */
router.post(
  '/bind',
  [
    body('bindCode').trim().isLength({ min: 6, max: 6 }).withMessage('绑定码为6位数字'),
    body('deviceId').trim().notEmpty().withMessage('设备ID不能为空'),
    validate,
  ],
  deviceController.bindDevice
);

/**
 * 获取当前用户的设备列表
 * GET /api/v1/devices
 */
router.get('/', deviceController.listDevices);

/**
 * 解绑设备
 * POST /api/v1/devices/:bindingId/unbind
 */
router.post('/:bindingId/unbind', deviceController.unbindDevice);

/**
 * 设备心跳
 * PUT /api/v1/devices/:deviceId/heartbeat
 */
router.put('/:deviceId/heartbeat', deviceController.heartbeat);

module.exports = router;
