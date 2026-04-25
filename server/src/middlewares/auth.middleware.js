/**
 * JWT 认证中间件
 * 验证请求头中的 Access Token
 */
const { verifyAccessToken } = require('../config/jwt');
const { unauthorized } = require('../utils/response');
const UserModel = require('../models/User.model');
const logger = require('../utils/logger');

/**
 * JWT 认证中间件
 * 从 Authorization header 中提取并验证 token
 */
async function authMiddleware(req, res, next) {
  try {
    // 获取 Authorization header
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return unauthorized(res, '缺少认证令牌');
    }

    const token = authHeader.substring(7); // 去掉 "Bearer " 前缀

    if (!token) {
      return unauthorized(res, '认证令牌为空');
    }

    // 验证 token
    const decoded = verifyAccessToken(token);

    // 从数据库查询用户（确保用户仍然有效）
    const user = await UserModel.findById(decoded.userId);

    if (!user) {
      return unauthorized(res, '用户不存在');
    }

    if (user.status !== 1) {
      return unauthorized(res, '账号已被禁用');
    }

    // 将用户信息挂载到请求对象上
    req.user = {
      id: user.id,
      username: user.username,
      realName: user.real_name,
      role: user.role,
      phone: user.phone,
      avatar: user.avatar,
    };

    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return unauthorized(res, '认证令牌已过期');
    }
    if (error.name === 'JsonWebTokenError') {
      return unauthorized(res, '无效的认证令牌');
    }
    logger.error('认证中间件异常:', error);
    return unauthorized(res, '认证失败');
  }
}

/**
 * 可选认证中间件
 * 如果有 token 则验证，没有则跳过（用于公开接口）
 */
async function optionalAuth(req, res, next) {
  try {
    const authHeader = req.headers.authorization;

    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.substring(7);
      if (token) {
        const decoded = verifyAccessToken(token);
        const user = await UserModel.findById(decoded.userId);
        if (user && user.status === 1) {
          req.user = {
            id: user.id,
            username: user.username,
            realName: user.real_name,
            role: user.role,
          };
        }
      }
    }
  } catch {
    // 忽略错误，继续处理请求
  }
  next();
}

module.exports = { authMiddleware, optionalAuth };
