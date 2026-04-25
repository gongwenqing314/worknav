/**
 * 认证控制器
 * 处理登录、注册、Token 刷新等请求
 */
const authService = require('../services/auth.service');
const { success, created, error } = require('../utils/response');
const logger = require('../utils/logger');

class AuthController {
  /**
   * 用户注册
   * POST /api/v1/auth/register
   */
  async register(req, res, next) {
    try {
      const { username, password, realName, phone, role } = req.body;

      const userId = await authService.register({
        username,
        password,
        realName,
        phone,
        role,
      });

      return created(res, { userId }, '注册成功');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 用户登录
   * POST /api/v1/auth/login
   */
  async login(req, res, next) {
    try {
      const { username, phone, password } = req.body;
      
      // 支持用户名或手机号登录
      const loginIdentifier = username || phone;
      if (!loginIdentifier) {
        return error(res, 400, '请输入用户名或手机号');
      }

      const result = await authService.login(loginIdentifier, password);

      return success(res, result, '登录成功');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 刷新 Token
   * POST /api/v1/auth/refresh
   */
  async refresh(req, res, next) {
    try {
      const { refreshToken } = req.body;

      if (!refreshToken) {
        return error(res, 400, '缺少 refresh token');
      }

      const result = await authService.refreshToken(refreshToken);

      return success(res, result, 'Token 刷新成功');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 用户登出
   * POST /api/v1/auth/logout
   */
  async logout(req, res, next) {
    try {
      await authService.logout(req.user.id);
      return success(res, null, '登出成功');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 修改密码
   * PUT /api/v1/auth/password
   */
  async changePassword(req, res, next) {
    try {
      const { oldPassword, newPassword } = req.body;

      await authService.changePassword(req.user.id, oldPassword, newPassword);

      return success(res, null, '密码修改成功');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 获取当前用户信息
   * GET /api/v1/auth/me
   */
  async getMe(req, res, next) {
    try {
      return success(res, req.user);
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new AuthController();
