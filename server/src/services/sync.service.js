/**
 * 离线同步服务
 * 处理客户端离线操作的上传和同步
 */
const SyncQueueModel = require('../models/SyncQueue.model');
const logger = require('../utils/logger');

class SyncService {
  /**
   * 客户端上报离线操作
   */
  async uploadOfflineData(userId, deviceId, operations) {
    const results = [];

    for (const op of operations) {
      try {
        const queueId = await SyncQueueModel.enqueue({
          userId,
          deviceId,
          action: op.action, // create / update / delete
          tableName: op.tableName,
          recordId: op.recordId,
          payload: op.payload,
        });
        results.push({ success: true, queueId, clientOpId: op.clientOpId });
      } catch (err) {
        logger.error(`离线数据入队失败:`, err.message);
        results.push({ success: false, error: err.message, clientOpId: op.clientOpId });
      }
    }

    return results;
  }

  /**
   * 处理同步队列（服务端消费）
   * 根据操作类型执行对应的数据库操作
   */
  async processSyncQueue(userId, deviceId) {
    const pendingItems = await SyncQueueModel.getPendingQueue(userId, deviceId);
    const results = [];

    for (const item of pendingItems) {
      try {
        // 根据表名和操作类型处理
        await this._processItem(item);
        await SyncQueueModel.markSynced(item.id);
        results.push({ success: true, queueId: item.id });
      } catch (err) {
        logger.error(`同步处理失败 (队列ID: ${item.id}):`, err.message);
        await SyncQueueModel.markFailed(item.id, err.message);
        results.push({ success: false, queueId: item.id, error: err.message });
      }
    }

    return results;
  }

  /**
   * 处理单个同步项
   * @private
   */
  async _processItem(item) {
    const { pool } = require('../config/database');
    const payload = typeof item.payload === 'string' ? JSON.parse(item.payload) : item.payload;

    // 根据表名映射到对应的处理逻辑
    const tableHandlers = {
      emotion_records: this._handleEmotionRecord,
      step_executions: this._handleStepExecution,
    };

    const handler = tableHandlers[item.table_name];
    if (handler) {
      await handler(item, payload);
    } else {
      logger.warn(`未知的同步表: ${item.table_name}`);
    }
  }

  /**
   * 处理情绪记录同步
   * @private
   */
  async _handleEmotionRecord(item, payload) {
    const EmotionRecordModel = require('../models/EmotionRecord.model');
    const EmotionService = require('./emotion.service');

    if (item.action === 'create') {
      await EmotionService.recordEmotion({
        employeeId: item.user_id,
        emotionType: payload.emotionType,
        intensity: payload.intensity,
        trigger: payload.trigger,
        note: payload.note,
        recordedAt: payload.recordedAt,
      });
    }
  }

  /**
   * 处理步骤执行同步
   * @private
   */
  async _handleStepExecution(item, payload) {
    const StepExecutionModel = require('../models/StepExecution.model');

    if (item.action === 'update') {
      if (payload.status === 'completed') {
        await StepExecutionModel.updateStatus(item.record_id, 'completed', {
          durationSeconds: payload.durationSeconds,
          note: payload.note,
        });
      }
    }
  }

  /**
   * 获取同步状态
   */
  async getSyncStatus(userId, deviceId) {
    const pending = await SyncQueueModel.getPendingQueue(userId, deviceId);
    const failed = await SyncQueueModel.getFailedQueue(userId, deviceId);

    return {
      pendingCount: pending.length,
      failedCount: failed.length,
      failedItems: failed,
    };
  }

  /**
   * 清理已同步记录
   */
  async cleanSyncedRecords(days = 7) {
    const count = await SyncQueueModel.cleanSynced(days);
    logger.info(`清理已同步记录: ${count} 条`);
    return count;
  }
}

module.exports = new SyncService();
