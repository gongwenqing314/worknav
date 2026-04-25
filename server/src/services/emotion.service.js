/**
 * 情绪预警服务
 * 处理情绪记录的创建、连续消极情绪检测和预警通知
 */
const EmotionRecordModel = require('../models/EmotionRecord.model');
const EmotionAlertRuleModel = require('../models/EmotionAlertRule.model');
const EmployeeCounselorModel = require('../models/EmployeeCounselor.model');
const EmployeeParentModel = require('../models/EmployeeParent.model');
const NotificationService = require('./notification.service');
const logger = require('../utils/logger');
const { isNegativeEmotion } = require('../utils/helpers');

class EmotionService {
  /**
   * 记录情绪并自动检测预警
   */
  async recordEmotion({ employeeId, emotionType, intensity, trigger, note, recordedAt }) {
    // 创建情绪记录
    const recordId = await EmotionRecordModel.create({
      employeeId,
      emotionType,
      intensity,
      trigger,
      note,
      recordedAt,
    });

    // 如果是消极情绪，触发预警检测
    if (isNegativeEmotion(emotionType)) {
      await this._checkAndAlert(employeeId, emotionType, intensity);
    }

    return recordId;
  }

  /**
   * 检查连续消极情绪并触发预警
   * @private
   */
  async _checkAndAlert(employeeId, currentEmotionType, currentIntensity) {
    try {
      // 获取该员工的预警规则
      const rules = await EmotionAlertRuleModel.findByEmployee(employeeId);

      if (rules.length === 0) return;

      // 获取最近N天的情绪记录
      const maxDays = Math.max(...rules.map(r => r.consecutive_days));
      const recentRecords = await EmotionRecordModel.getRecentRecords(employeeId, maxDays);

      if (recentRecords.length === 0) return;

      // 按天分组统计消极情绪
      const dailyNegatives = {};
      for (const record of recentRecords) {
        const date = record.recorded_at.toISOString().slice(0, 10);
        if (!dailyNegatives[date]) dailyNegatives[date] = [];

        // 检查是否符合规则条件
        for (const rule of rules) {
          const negativeTypes = typeof rule.negative_types === 'string'
            ? JSON.parse(rule.negative_types)
            : rule.negative_types;

          if (negativeTypes.includes(record.emotion_type) && record.intensity >= rule.min_intensity) {
            dailyNegatives[date].push({
              emotionType: record.emotion_type,
              intensity: record.intensity,
              ruleId: rule.id,
            });
          }
        }
      }

      // 检查每条规则是否触发
      for (const rule of rules) {
        const consecutiveDays = this._countConsecutiveNegativeDays(dailyNegatives, rule);

        if (consecutiveDays >= rule.consecutive_days) {
          // 触发预警
          await this._triggerAlert(employeeId, rule, consecutiveDays);
        }
      }
    } catch (err) {
      logger.error(`情绪预警检测失败 (员工ID: ${employeeId}):`, err.message);
    }
  }

  /**
   * 计算连续消极情绪天数
   * @private
   */
  _countConsecutiveNegativeDays(dailyNegatives, rule) {
    const negativeTypes = typeof rule.negative_types === 'string'
      ? JSON.parse(rule.negative_types)
      : rule.negative_types;

    const dates = Object.keys(dailyNegatives).sort().reverse(); // 从最近日期开始
    let consecutiveCount = 0;

    for (const date of dates) {
      const dayRecords = dailyNegatives[date];
      const hasMatch = dayRecords.some(r =>
        negativeTypes.includes(r.emotionType) && r.intensity >= rule.min_intensity
      );

      if (hasMatch) {
        consecutiveCount++;
      } else {
        break; // 一旦某天没有消极情绪，连续计数中断
      }
    }

    return consecutiveCount;
  }

  /**
   * 触发情绪预警通知
   * @private
   */
  async _triggerAlert(employeeId, rule, consecutiveDays) {
    logger.warn(`情绪预警触发: 员工(${employeeId}), 连续${consecutiveDays}天消极情绪`);

    const alertTitle = '情绪预警通知';
    const alertContent = `该员工已连续${consecutiveDays}天出现消极情绪（强度 >= ${rule.min_intensity}），请及时关注并提供支持。`;

    // 通知辅导员
    if (rule.notify_counselor) {
      const counselors = await EmployeeCounselorModel.getCounselorsByEmployee(employeeId);
      const counselorIds = counselors.map(c => c.counselor_id);
      if (counselorIds.length > 0) {
        await NotificationService.sendToUsers(counselorIds, {
          type: 'emotion_alert',
          title: alertTitle,
          content: alertContent,
          data: { employeeId, consecutiveDays, ruleId: rule.id },
        });
      }
    }

    // 通知家长
    if (rule.notify_parent) {
      const parents = await EmployeeParentModel.getParentsByEmployee(employeeId);
      const parentIds = parents.map(p => p.parent_id);
      if (parentIds.length > 0) {
        await NotificationService.sendToUsers(parentIds, {
          type: 'emotion_alert',
          title: alertTitle,
          content: alertContent,
          data: { employeeId, consecutiveDays, ruleId: rule.id },
        });
      }
    }
  }

  /**
   * 获取情绪统计
   */
  async getEmotionStats(employeeId, { startDate, endDate } = {}) {
    const stats = await EmotionRecordModel.getEmotionStats(employeeId, { startDate, endDate });
    const trend = await EmotionRecordModel.getEmotionTrend(employeeId, 30);

    return { stats, trend };
  }
}

module.exports = new EmotionService();
