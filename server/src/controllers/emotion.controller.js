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
      const { employeeId, negativeTypes, consecutiveDays, minIntensity, notifyCounselor, notifyParent } = req.body;

      const ruleId = await EmotionAlertRuleModel.create({
        employeeId,
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
}

module.exports = new EmotionController();
