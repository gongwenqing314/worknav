/**
 * 远程协助会话模型
 */
const { pool } = require('../config/database');

class AssistSessionModel {
  /**
   * 根据ID查找会话
   */
  static async findById(id) {
    const [rows] = await pool.execute(
      `SELECT s.*,
              ue.real_name as employee_name, ue.avatar as employee_avatar,
              uh.real_name as helper_name, uh.avatar as helper_avatar
       FROM assist_sessions s
       JOIN users ue ON s.employee_id = ue.id
       LEFT JOIN users uh ON s.helper_id = uh.id
       WHERE s.id = ?`,
      [id]
    );
    return rows[0] || null;
  }

  /**
   * 获取员工的协助会话列表
   */
  static async findByEmployee(employeeId, { offset = 0, limit = 20, status = null } = {}) {
    const conditions = ['s.employee_id = ?'];
    const params = [employeeId];

    if (status) {
      conditions.push('s.status = ?');
      params.push(status);
    }

    const safeOffset = parseInt(offset, 10) || 0;
    const safeLimit = parseInt(limit, 10) || 20;

    const [rows] = await pool.execute(
      `SELECT s.*, uh.real_name as helper_name
       FROM assist_sessions s
       LEFT JOIN users uh ON s.helper_id = uh.id
       WHERE ${conditions.join(' AND ')}
       ORDER BY s.created_at DESC
       LIMIT ${safeOffset}, ${safeLimit}`,
      params
    );
    return rows;
  }

  /**
   * 获取辅导员的协助会话列表
   */
  static async findByHelper(helperId, { offset = 0, limit = 20, status = null } = {}) {
    const conditions = ['s.helper_id = ?'];
    const params = [helperId];

    if (status) {
      conditions.push('s.status = ?');
      params.push(status);
    }

    const safeOffset = parseInt(offset, 10) || 0;
    const safeLimit = parseInt(limit, 10) || 20;

    const [rows] = await pool.execute(
      `SELECT s.*, ue.real_name as employee_name, ue.avatar as employee_avatar
       FROM assist_sessions s
       JOIN users ue ON s.employee_id = ue.id
       WHERE ${conditions.join(' AND ')}
       ORDER BY s.created_at DESC
       LIMIT ${safeOffset}, ${safeLimit}`,
      params
    );
    return rows;
  }

  /**
   * 获取待接听的协助请求
   */
  static async findPendingSessions() {
    const [rows] = await pool.execute(
      `SELECT s.*, ue.real_name as employee_name, ue.avatar as employee_avatar,
              ep.workplace, ep.job_title
       FROM assist_sessions s
       JOIN users ue ON s.employee_id = ue.id
       LEFT JOIN employee_profiles ep ON s.employee_id = ep.user_id
       WHERE s.status = 'pending'
       ORDER BY s.created_at ASC`
    );
    return rows;
  }

  /**
   * 创建协助会话
   */
  static async create({ employeeId, requestType, description, photoUrl }) {
    const [result] = await pool.execute(
      `INSERT INTO assist_sessions (employee_id, request_type, description, photo_url)
       VALUES (?, ?, ?, ?)`,
      [employeeId, requestType || null, description || null, photoUrl || null]
    );
    return result.insertId;
  }

  /**
   * 接听协助请求
   */
  static async accept(id, helperId) {
    const [result] = await pool.execute(
      'UPDATE assist_sessions SET helper_id = ?, status = ?, started_at = NOW() WHERE id = ? AND status = ?',
      [helperId, 'active', id, 'pending']
    );
    return result.affectedRows;
  }

  /**
   * 结束协助会话
   */
  static async end(id, { rating = null, feedback = null } = {}) {
    const [result] = await pool.execute(
      'UPDATE assist_sessions SET status = ?, ended_at = NOW(), rating = ?, feedback = ? WHERE id = ?',
      ['ended', rating, feedback, id]
    );
    return result.affectedRows;
  }

  /**
   * 更新标注图片
   */
  static async updateAnnotation(id, annotationUrl) {
    const [result] = await pool.execute(
      'UPDATE assist_sessions SET annotation_url = ? WHERE id = ?',
      [annotationUrl, id]
    );
    return result.affectedRows;
  }
}

module.exports = AssistSessionModel;
