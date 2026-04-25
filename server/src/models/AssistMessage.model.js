/**
 * 远程协助消息模型
 */
const { pool } = require('../config/database');

class AssistMessageModel {
  /**
   * 获取会话的消息列表
   */
  static async findBySession(sessionId, { offset = 0, limit = 50 } = {}) {
    const safeOffset = parseInt(offset, 10) || 0;
    const safeLimit = parseInt(limit, 10) || 50;
    const [rows] = await pool.execute(
      `SELECT m.*, u.real_name as sender_name, u.avatar as sender_avatar
       FROM assist_messages m
       JOIN users u ON m.sender_id = u.id
       WHERE m.session_id = ?
       ORDER BY m.created_at ASC
       LIMIT ${safeOffset}, ${safeLimit}`,
      [sessionId]
    );
    return rows;
  }

  /**
   * 创建消息
   */
  static async create({ sessionId, senderId, senderRole, type, content, fileUrl }) {
    const [result] = await pool.execute(
      `INSERT INTO assist_messages (session_id, sender_id, sender_role, type, content, file_url)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [sessionId, senderId, senderRole, type || 'text', content || null, fileUrl || null]
    );
    return result.insertId;
  }

  /**
   * 获取会话最新消息
   */
  static async getLatest(sessionId) {
    const [rows] = await pool.execute(
      `SELECT m.*, u.real_name as sender_name
       FROM assist_messages m
       JOIN users u ON m.sender_id = u.id
       WHERE m.session_id = ?
       ORDER BY m.created_at DESC
       LIMIT 1`,
      [sessionId]
    );
    return rows[0] || null;
  }

  /**
   * 获取会话消息数量
   */
  static async countBySession(sessionId) {
    const [rows] = await pool.execute(
      'SELECT COUNT(*) as total FROM assist_messages WHERE session_id = ?',
      [sessionId]
    );
    return rows[0].total;
  }
}

module.exports = AssistMessageModel;
