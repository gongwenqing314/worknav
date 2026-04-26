/**
 * 情绪记录控制器
 * 处理情绪记录的创建、查询和预警规则管理
 */
const emotionService = require('../services/emotion.service');
const EmotionAlertRuleModel = require('../models/EmotionAlertRule.model');
const { success, created, notFound } = require('../utils/response');
const { parsePagination, paginationMeta } = require('../utils/helpers');

class EmotionController {
  /**
   * 记录情绪
   * POST /api/v1/emotions
   */
  async record(req, res, next) {
    try {
      const { emotionType, intensity, trigger, note, recordedAt } = req.body;

      const recordId = await emotionService.recordEmotion({
        employeeId: req.params.employeeId || req.user.id,
        emotionType,
        intensity,
        trigger,
        note,
        recordedAt,
      });

      return created(res, { recordId }, '情绪记录成功');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 获取情绪记录列表
   * GET /api/v1/emotions/:employeeId
   */
  async list(req, res, next) {
    try {
      const { startDate, endDate, emotionType } = req.query;
      const { offset, limit, page, pageSize } = parsePagination(req.query);

      const EmotionRecordModel = require('../models/EmotionRecord.model');
      const records = await EmotionRecordModel.findByEmployee(req.params.employeeId, {
        offset, limit, startDate, endDate, emotionType,
      });

      const total = await EmotionRecordModel.countByEmployee(req.params.employeeId, { startDate, endDate });

      return success(res, {
        list: records,
        pagination: paginationMeta(total, page, pageSize),
      });
    } catch (err) {
      next(err);
    }
  }

  /**
   * 获取情绪统计
   * GET /api/v1/emotions/:employeeId/stats
   */
  async getStats(req, res, next) {
    try {
      const { startDate, endDate } = req.query;
      const stats = await emotionService.getEmotionStats(req.params.employeeId, { startDate, endDate });
      return success(res, stats);
    } catch (err) {
      next(err);
    }
  }

  // ========== 情绪预警规则管理 ==========

  /**
   * 获取预警规则列表
   * GET /api/v1/emotions/alert-rules
   */
  async listAlertRules(req, res, next) {
    try {
      const employeeId = req.query.employeeId || null;
      let rules;

      if (employeeId) {
        rules = await EmotionAlertRuleModel.findByEmployee(parseInt(employeeId));
      } else {
        rules = await EmotionAlertRuleModel.findActiveRules();
      }

      return success(res, rules);
    } catch (err) {
      next(err);
    }
  }

  /**
   * 创建预警规则
   * POST /api/v1/emotions/alert-rules
   */
  async createAlertRule(req, res, next) {
    try {
      const { employeeId, name, negativeTypes, consecutiveDays, minIntensity, notifyCounselor, notifyParent } = req.body;

      const ruleId = await EmotionAlertRuleModel.create({
        employeeId,
        name,
        negativeTypes,
        consecutiveDays,
        minIntensity,
        notifyCounselor,
        notifyParent,
      });

      return created(res, { ruleId }, '预警规则创建成功');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 更新预警规则
   * PUT /api/v1/emotions/alert-rules/:ruleId
   */
  async updateAlertRule(req, res, next) {
    try {
      await EmotionAlertRuleModel.update(req.params.ruleId, req.body);
      return success(res, null, '预警规则更新成功');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 删除预警规则
   * DELETE /api/v1/emotions/alert-rules/:ruleId
   */
  async deleteAlertRule(req, res, next) {
    try {
      await EmotionAlertRuleModel.delete(req.params.ruleId);
      return success(res, null, '预警规则已删除');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 获取所有员工的实时情绪概览
   * GET /api/v1/emotions/overview
   */
  async overview(req, res, next) {
    try {
      const EmotionRecordModel = require('../models/EmotionRecord.model');
      const User = require('../models/User.model');
      const pool = require('../config/database').pool;

      // 获取所有员工用户
      const employees = await User.findByRole('employee');
      const overview = [];

      for (const emp of employees) {
        // 获取该员工最近一条情绪记录
        const records = await EmotionRecordModel.findByEmployee(emp.id, { limit: 1 });
        const latest = records[0] || null;

        // 用 CURDATE() 查询今日情绪记录数（避免时区问题）
        const [countRows] = await pool.execute(
          `SELECT COUNT(*) as cnt FROM emotion_records WHERE employee_id = ? AND DATE(recorded_at) = CURDATE()`,
          [emp.id]
        );
        const todayCount = countRows[0].cnt;

        overview.push({
          employeeId: emp.id,
          employeeName: emp.real_name || emp.username,
          avatar: emp.avatar,
          latestEmotion: latest ? latest.emotion_type : null,
          latestIntensity: latest ? latest.intensity : null,
          latestTime: latest ? latest.recorded_at : null,
          todayRecordCount: todayCount,
        });
      }

      return success(res, overview);
    } catch (err) {
      next(err);
    }
  }

  /**
   * 获取预警列表（基于情绪记录中的消极情绪）
   * GET /api/v1/emotions/alerts
   */
  async alerts(req, res, next) {
    try {
      const EmotionRecordModel = require('../models/EmotionRecord.model');
      const User = require('../models/User.model');

      // 查询最近的消极情绪记录（anxious, sad, angry, confused）
      const negativeEmotions = ['anxious', 'sad', 'angry', 'confused'];
      const { offset, limit, page, pageSize } = parsePagination(req.query);
      const { handled } = req.query;

      const alerts = await EmotionRecordModel.findNegative({
        emotions: negativeEmotions,
        offset,
        limit,
        // '' 或 'all' → undefined(查全部), 'unhandled' → false(查未处理), 'handled' → true(查已处理)
        handled: (handled === 'unhandled') ? false : (handled === 'handled' ? true : undefined),
      });

      // 补充员工信息
      const alertsWithInfo = [];
      for (const alert of alerts) {
        const user = await User.findById(alert.employee_id);
        alertsWithInfo.push({
          id: alert.id,
          employeeId: alert.employee_id,
          employeeName: user ? (user.real_name || user.username) : '未知',
          emotionType: alert.emotion_type,
          intensity: alert.intensity,
          trigger: alert.trigger,
          recordedAt: alert.recorded_at,
          handled: !!alert.handled,
          handledAt: alert.handled_at,
          handledBy: alert.handled_by,
        });
      }

      return success(res, {
        list: alertsWithInfo,
        pagination: paginationMeta(alertsWithInfo.length, page, pageSize),
      });
    } catch (err) {
      next(err);
    }
  }

  /**
   * 处理预警（标记为已处理）
   * POST /api/v1/emotions/alerts/:alertId/handle
   */
  async handleAlert(req, res, next) {
    try {
      const { alertId } = req.params;
      const { action, note } = req.body;

      const EmotionRecordModel = require('../models/EmotionRecord.model');
      await EmotionRecordModel.markHandled(alertId, {
        handledBy: req.user.id,
        note: note || action || '已查看',
      });

      return success(res, { alertId, handledAt: new Date() }, '预警已处理');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 获取今日情绪记录（员工端）
   * GET /api/v1/emotions/today
   */
  async todayRecords(req, res, next) {
    try {
      const EmotionRecordModel = require('../models/EmotionRecord.model');
      const records = await EmotionRecordModel.findByEmployee(req.user.id, {
        startDate: new Date().toISOString().slice(0, 10),
        endDate: new Date().toISOString().slice(0, 10),
        limit: 50,
      });
      return success(res, records);
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new EmotionController();
