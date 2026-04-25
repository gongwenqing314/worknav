/**
 * 认证服务
 * 处理登录、注册、Token 刷新等认证逻辑
 */
const bcrypt = require('bcryptjs');
const UserModel = require('../models/User.model');
const EmployeeProfileModel = require('../models/EmployeeProfile.model');
const { generateAccessToken, generateRefreshToken, verifyRefreshToken } = require('../config/jwt');
const { redis } = require('../config/redis');
const logger = require('../utils/logger');

class AuthService {
  /**
   * 用户注册
   */
  async register({ username, password, realName, phone, role }) {
    // 检查用户名是否已存在
    const existingUser = await UserModel.findByUsername(username);
    if (existingUser) {
      throw new Error('用户名已存在');
    }

    // 检查手机号是否已被使用
    if (phone) {
      const existingPhone = await UserModel.findByPhone(phone);
      if (existingPhone) {
        throw new Error('手机号已被使用');
      }
    }

    // 加密密码
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    // 创建用户
    const userId = await UserModel.create({
      username,
      passwordHash,
      realName,
      phone,
      role,
    });

    // 如果是员工角色，自动创建员工档案
    if (role === 'employee') {
      await EmployeeProfileModel.create({ userId });
    }

    logger.info(`用户注册成功: ${username} (ID: ${userId})`);
    return userId;
  }

  /**
   * 用户登录
   */
  async login(loginIdentifier, password) {
    // 查找用户（先尝试用户名，再尝试手机号）
    let user = await UserModel.findByUsername(loginIdentifier);
    if (!user) {
      user = await UserModel.findByPhone(loginIdentifier);
    }
    if (!user) {
      throw new Error('用户名或密码错误');
    }

    // 检查账号状态
    if (user.status !== 1) {
      throw new Error('账号已被禁用');
    }

    // 验证密码
    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      throw new Error('用户名或密码错误');
    }

    // 更新最后登录时间
    await UserModel.updateLastLogin(user.id);

    // 生成 token
    const tokenPayload = {
      userId: user.id,
      username: user.username,
      role: user.role,
    };

    const accessToken = generateAccessToken(tokenPayload);
    const refreshToken = generateRefreshToken(tokenPayload);

    // 将 refresh token 存入 Redis（用于后续验证和撤销）
    try {
      await redis.set(
        `refresh_token:${user.id}`,
        refreshToken,
        'EX',
        7 * 24 * 60 * 60 // 7天过期
      );
    } catch (error) {
      logger.warn(`Redis不可用，跳过存储refresh token: ${error.message}`);
    }

    logger.info(`用户登录成功: ${loginIdentifier} (ID: ${user.id})`);

    return {
      accessToken,
      refreshToken,
      user: {
        id: user.id,
        username: user.username,
        realName: user.real_name,
        phone: user.phone,
        avatar: user.avatar,
        role: user.role,
      },
    };
  }

  /**
   * 刷新 Access Token
   */
  async refreshToken(refreshTokenStr) {
    // 验证 refresh token
    let decoded;
    try {
      decoded = verifyRefreshToken(refreshTokenStr);
    } catch {
      throw new Error('Refresh Token 无效或已过期');
    }

    // 检查 Redis 中存储的 refresh token 是否匹配
    const storedToken = await redis.get(`refresh_token:${decoded.userId}`);
    if (!storedToken || storedToken !== refreshTokenStr) {
      throw new Error('Refresh Token 已被撤销');
    }

    // 检查用户是否仍然有效
    const user = await UserModel.findById(decoded.userId);
    if (!user || user.status !== 1) {
      throw new Error('用户不存在或已被禁用');
    }

    // 生成新的 access token
    const tokenPayload = {
      userId: user.id,
      username: user.username,
      role: user.role,
    };

    const newAccessToken = generateAccessToken(tokenPayload);

    return { accessToken: newAccessToken };
  }

  /**
   * 用户登出（撤销 refresh token）
   */
  async logout(userId) {
    await redis.del(`refresh_token:${userId}`);
    logger.info(`用户登出: (ID: ${userId})`);
  }

  /**
   * 修改密码
   */
  async changePassword(userId, oldPassword, newPassword) {
    const user = await UserModel.findByUsername(
      (await UserModel.findById(userId)).username
    );

    // 验证旧密码
    const isMatch = await bcrypt.compare(oldPassword, user.password_hash);
    if (!isMatch) {
      throw new Error('旧密码错误');
    }

    // 加密新密码
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(newPassword, salt);

    // 更新密码
    await UserModel.updatePassword(userId, passwordHash);

    // 撤销所有 refresh token（强制重新登录）
    await redis.del(`refresh_token:${userId}`);

    logger.info(`用户修改密码: (ID: ${userId})`);
  }
}

module.exports = new AuthService();
