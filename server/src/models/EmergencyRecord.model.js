/**
 * 应急记录模型
 */
const { pool } = require('../config/database');

class EmergencyRecordModel {
  /**
   * 创建应急记录
   */
  static async create({ employeeId, type, description, location }) {
    const [result] = await pool.execute(
      `INSERT INTO emergency_records (employee_id, type, description, location)
       VALUES (?, ?, ?, ?)`,
      [employeeId, type, description || null, location || null]
    );
    return result.insertId;
  }

  /**
   * 获取应急记录列表
   */
  static async findAll({ offset = 0, limit = 20, status = null, employeeId = null } = {}) {
    const conditions = [];
    const params = [];

    if (employeeId) {
      conditions.push('e.employee_id = ?');
      params.push(employeeId);
    }
    if (status) {
      conditions.push('e.status = ?');
      params.push(status);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    const safeOffset = parseInt(offset, 10) || 0;
    const safeLimit = parseInt(limit, 10) || 20;

    const [rows] = await pool.execute(
      `SELECT e.*, u.real_name as employee_name, uh.real_name as handler_name
       FROM emergency_records e
       JOIN users u ON e.employee_id = u.id
       LEFT JOIN users uh ON e.handler_id = uh.id
       ${whereClause}
       ORDER BY e.created_at DESC
       LIMIT ${safeOffset}, ${safeLimit}`,
      params
    );
    return rows;
  }

  /**
   * 处理应急事件
   */
  static async resolve(id, handlerId, resolution) {
    const [result] = await pool.execute(
      'UPDATE emergency_records SET handler_id = ?, status = ?, resolution = ? WHERE id = ?',
      [handlerId, 'resolved', resolution || null, id]
    );
    return result.affectedRows;
  }

  /**
   * 根据ID查找
   */
  static async findById(id) {
    const [rows] = await pool.execute(
      `SELECT e.*, u.real_name as employee_name, uh.real_name as handler_name
       FROM emergency_records e
       JOIN users u ON e.employee_id = u.id
       LEFT JOIN users uh ON e.handler_id = uh.id
       WHERE e.id = ?`,
      [id]
    );
    return rows[0] || null;
  }
}

module.exports = EmergencyRecordModel;
