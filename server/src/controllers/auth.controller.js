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

  /**
   * 设备自动登录（员工端）
   * POST /api/v1/auth/device-login
   */
  async deviceLogin(req, res, next) {
    try {
      const { deviceId } = req.body;
      const { pool } = require('../config/database');
      const User = require('../models/User.model');
      const { generateAccessToken, generateRefreshToken } = require('../config/jwt');

      // 查找已绑定该设备的员工
      const [bindings] = await pool.execute(
        'SELECT * FROM device_bindings WHERE device_id = ? AND is_bound = 1 LIMIT 1',
        [deviceId]
      );
      const binding = bindings[0];

      if (!binding || !binding.user_id) {
        return res.status(401).json({
          code: 401,
          message: '设备未绑定员工账号，请联系辅导员绑定设备',
          data: { needBinding: true },
        });
      }

      const user = await User.findById(binding.user_id);
      if (!user || user.status !== 1) {
        return res.status(401).json({
          code: 401,
          message: '关联的员工账号已禁用',
          data: null,
        });
      }

      // 生成 Token
      const accessToken = generateAccessToken({ id: user.id, username: user.username, role: user.role });
      const refreshToken = generateRefreshToken({ id: user.id });

      // 更新设备最后活跃时间
      await pool.execute(
        'UPDATE device_bindings SET last_active_at = NOW() WHERE device_id = ?',
        [deviceId]
      );

      return res.status(200).json({
        code: 200,
        message: 'success',
        data: {
          accessToken,
          refreshToken,
          employeeId: String(user.id),
          employeeName: user.real_name || user.username,
        },
      });
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new AuthController();
