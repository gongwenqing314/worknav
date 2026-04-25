/**
 * 设备管理控制器
 * 处理设备绑定、解绑和绑定码管理
 */
const { pool } = require('../config/database');
const { generateBindCode } = require('../utils/helpers');
const { success, created, notFound } = require('../utils/response');
const logger = require('../utils/logger');

class DeviceController {
  /**
   * 生成绑定码
   * POST /api/v1/devices/bind-code
   */
  async generateBindCode(req, res, next) {
    try {
      const bindCode = generateBindCode();

      // 将绑定码存入 Redis，有效期 10 分钟
      const { redis } = require('../config/redis');
      await redis.set(
        `bind_code:${bindCode}`,
        JSON.stringify({ userId: req.user.id, createdAt: new Date().toISOString() }),
        'EX',
        600 // 10分钟
      );

      return success(res, { bindCode }, '绑定码已生成，有效期10分钟');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 使用绑定码绑定设备
   * POST /api/v1/devices/bind
   */
  async bindDevice(req, res, next) {
    try {
      const { bindCode, deviceId, deviceName } = req.body;

      if (!bindCode || !deviceId) {
        return res.status(400).json({ code: 400, message: '请提供绑定码和设备ID', data: null });
      }

      const { redis } = require('../config/redis');

      // 从 Redis 获取绑定码信息
      const codeData = await redis.get(`bind_code:${bindCode}`);
      if (!codeData) {
        return res.status(400).json({ code: 400, message: '绑定码无效或已过期', data: null });
      }

      const { userId } = JSON.parse(codeData);

      // 检查设备是否已被绑定
      const [existing] = await pool.execute(
        'SELECT id, user_id FROM device_bindings WHERE device_id = ? AND is_bound = 1',
        [deviceId]
      );

      if (existing.length > 0) {
        if (existing[0].user_id === userId) {
          return success(res, null, '设备已绑定到当前账号');
        }
        return res.status(400).json({ code: 400, message: '该设备已被其他账号绑定', data: null });
      }

      // 创建绑定记录
      const [result] = await pool.execute(
        `INSERT INTO device_bindings (user_id, device_id, device_name, bind_code, is_bound)
         VALUES (?, ?, ?, ?, 1)`,
        [userId, deviceId, deviceName || null, bindCode]
      );

      // 删除已使用的绑定码
      await redis.del(`bind_code:${bindCode}`);

      logger.info(`设备绑定成功: 用户(${userId}), 设备(${deviceId})`);

      return created(res, { bindingId: result.insertId }, '设备绑定成功');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 解绑设备
   * POST /api/v1/devices/:bindingId/unbind
   */
  async unbindDevice(req, res, next) {
    try {
      const [result] = await pool.execute(
        'UPDATE device_bindings SET is_bound = 0 WHERE id = ? AND user_id = ?',
        [req.params.bindingId, req.user.id]
      );

      if (result.affectedRows === 0) {
        return notFound(res, '绑定记录不存在');
      }

      return success(res, null, '设备已解绑');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 获取当前用户的设备列表
   * GET /api/v1/devices
   */
  async listDevices(req, res, next) {
    try {
      const [rows] = await pool.execute(
        'SELECT * FROM device_bindings WHERE user_id = ? AND is_bound = 1 ORDER BY last_active_at DESC',
        [req.user.id]
      );
      return success(res, rows);
    } catch (err) {
      next(err);
    }
  }

  /**
   * 更新设备最后活跃时间
   * PUT /api/v1/devices/:deviceId/heartbeat
   */
  async heartbeat(req, res, next) {
    try {
      await pool.execute(
        'UPDATE device_bindings SET last_active_at = NOW() WHERE device_id = ? AND user_id = ? AND is_bound = 1',
        [req.params.deviceId, req.user.id]
      );
      return success(res, null, '心跳更新成功');
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new DeviceController();
