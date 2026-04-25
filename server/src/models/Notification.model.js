/**
 * 消息通知模型
 */
const { pool } = require('../config/database');

class NotificationModel {
  /**
   * 创建通知
   */
  static async create({ userId, type, title, content, data }) {
    const [result] = await pool.execute(
      `INSERT INTO notifications (user_id, type, title, content, data)
       VALUES (?, ?, ?, ?, ?)`,
      [userId, type, title, content || null, data ? JSON.stringify(data) : null]
    );
    return result.insertId;
  }

  /**
   * 批量创建通知（给多个用户发送相同通知）
   */
  static async batchCreate(userIds, { type, title, content, data }) {
    if (userIds.length === 0) return 0;

    const sql = `
      INSERT INTO notifications (user_id, type, title, content, data)
      VALUES ?
    `;
    const values = userIds.map(uid => [uid, type, title, content || null, data ? JSON.stringify(data) : null]);

    const [result] = await pool.query(sql, [values]);
    return result.affectedRows;
  }

  /**
   * 获取用户通知列表
   */
  static async findByUser(userId, { offset = 0, limit = 20, type = null, isRead = null } = {}) {
    const conditions = ['user_id = ?'];
    const params = [userId];

    if (type) {
      conditions.push('type = ?');
      params.push(type);
    }
    if (isRead !== null) {
      conditions.push('is_read = ?');
      params.push(isRead);
    }

    const safeOffset = parseInt(offset, 10) || 0;
    const safeLimit = parseInt(limit, 10) || 20;

    const [rows] = await pool.execute(
      `SELECT * FROM notifications
       WHERE ${conditions.join(' AND ')}
       ORDER BY created_at DESC
       LIMIT ${safeOffset}, ${safeLimit}`,
      params
    );
    return rows;
  }

  /**
   * 获取用户未读通知数量
   */
  static async getUnreadCount(userId) {
    const [rows] = await pool.execute(
      'SELECT COUNT(*) as total FROM notifications WHERE user_id = ? AND is_read = 0',
      [userId]
    );
    return rows[0].total;
  }

  /**
   * 标记通知为已读
   */
  static async markAsRead(id, userId) {
    const [result] = await pool.execute(
      'UPDATE notifications SET is_read = 1, read_at = NOW() WHERE id = ? AND user_id = ?',
      [id, userId]
    );
    return result.affectedRows;
  }

  /**
   * 标记用户所有通知为已读
   */
  static async markAllAsRead(userId) {
    const [result] = await pool.execute(
      'UPDATE notifications SET is_read = 1, read_at = NOW() WHERE user_id = ? AND is_read = 0',
      [userId]
    );
    return result.affectedRows;
  }

  /**
   * 删除通知
   */
  static async delete(id, userId) {
    const [result] = await pool.execute(
      'DELETE FROM notifications WHERE id = ? AND user_id = ?',
      [id, userId]
    );
    return result.affectedRows;
  }
}

module.exports = NotificationModel;
