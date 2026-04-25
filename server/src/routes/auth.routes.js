/**
 * 认证路由
 */
const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const authController = require('../controllers/auth.controller');
const { authMiddleware } = require('../middlewares/auth.middleware');
const { validate } = require('../middlewares/validator.middleware');

/**
 * 用户注册
 * POST /api/v1/auth/register
 */
router.post(
  '/register',
  [
    body('username').trim().isLength({ min: 3, max: 50 }).withMessage('用户名长度3-50个字符'),
    body('password').isLength({ min: 6 }).withMessage('密码至少6个字符'),
    body('realName').trim().notEmpty().withMessage('真实姓名不能为空'),
    body('role').isIn(['counselor', 'co_counselor', 'parent', 'employee', 'employer']).withMessage('无效的角色'),
    body('phone').optional().isMobilePhone('zh-CN').withMessage('手机号格式不正确'),
    validate,
  ],
  authController.register
);

/**
 * 用户登录
 * POST /api/v1/auth/login
 */
router.post(
  '/login',
  [
    body().custom((value) => {
      if (!value.username && !value.phone) {
        throw new Error('用户名或手机号不能为空');
      }
      return true;
    }),
    body('password').notEmpty().withMessage('密码不能为空'),
    validate,
  ],
  authController.login
);

/**
 * 刷新 Token
 * POST /api/v1/auth/refresh
 */
router.post(
  '/refresh',
  [
    body('refreshToken').notEmpty().withMessage('refreshToken不能为空'),
    validate,
  ],
  authController.refresh
);

/**
 * 用户登出（需要认证）
 * POST /api/v1/auth/logout
 */
router.post('/logout', authMiddleware, authController.logout);

/**
 * 修改密码（需要认证）
 * PUT /api/v1/auth/password
 */
router.put(
  '/password',
  authMiddleware,
  [
    body('oldPassword').notEmpty().withMessage('旧密码不能为空'),
    body('newPassword').isLength({ min: 6 }).withMessage('新密码至少6个字符'),
    validate,
  ],
  authController.changePassword
);

/**
 * 获取当前用户信息
 * GET /api/v1/auth/me
 */
router.get('/me', authMiddleware, authController.getMe);

module.exports = router;
