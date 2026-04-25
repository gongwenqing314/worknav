/**
 * 同步队列模型（离线同步用）
 */
const { pool } = require('../config/database');

class SyncQueueModel {
  /**
   * 添加同步任务
   */
  static async enqueue({ userId, deviceId, action, tableName, recordId, payload }) {
    const [result] = await pool.execute(
      `INSERT INTO sync_queue (user_id, device_id, action, table_name, record_id, payload)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [userId, deviceId, action, tableName, recordId || null, JSON.stringify(payload)]
    );
    return result.insertId;
  }

  /**
   * 获取用户的待同步队列
   */
  static async getPendingQueue(userId, deviceId) {
    const [rows] = await pool.execute(
      `SELECT * FROM sync_queue
       WHERE user_id = ? AND device_id = ? AND status = 'pending'
       ORDER BY created_at ASC`,
      [userId, deviceId]
    );
    return rows;
  }

  /**
   * 标记同步成功
   */
  static async markSynced(id) {
    const [result] = await pool.execute(
      'UPDATE sync_queue SET status = ?, synced_at = NOW() WHERE id = ?',
      ['synced', id]
    );
    return result.affectedRows;
  }

  /**
   * 批量标记同步成功
   */
  static async batchMarkSynced(ids) {
    if (ids.length === 0) return 0;
    const placeholders = ids.map(() => '?').join(',');
    const [result] = await pool.execute(
      `UPDATE sync_queue SET status = 'synced', synced_at = NOW() WHERE id IN (${placeholders})`,
      ids
    );
    return result.affectedRows;
  }

  /**
   * 标记同步失败
   */
  static async markFailed(id, errorMessage) {
    const [result] = await pool.execute(
      'UPDATE sync_queue SET status = ?, error_message = ? WHERE id = ?',
      ['failed', errorMessage, id]
    );
    return result.affectedRows;
  }

  /**
   * 清理已同步的记录（保留7天）
   */
  static async cleanSynced(days = 7) {
    const [result] = await pool.execute(
      'DELETE FROM sync_queue WHERE status = ? AND synced_at < DATE_SUB(NOW(), INTERVAL ? DAY)',
      ['synced', days]
    );
    return result.affectedRows;
  }

  /**
   * 获取同步失败的任务（用于重试）
   */
  static async getFailedQueue(userId, deviceId, { limit = 20 } = {}) {
    const [rows] = await pool.execute(
      `SELECT * FROM sync_queue
       WHERE user_id = ? AND device_id = ? AND status = 'failed'
       ORDER BY created_at ASC
       LIMIT ?`,
      [userId, deviceId, limit]
    );
    return rows;
  }
}

module.exports = SyncQueueModel;
