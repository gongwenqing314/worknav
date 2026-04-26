/**
 * 情绪记录模型
 */
const { pool } = require('../config/database');

class EmotionRecordModel {
  /**
   * 创建情绪记录
   */
  static async create({ employeeId, emotionType, intensity, trigger, note, recordedAt }) {
    const [result] = await pool.execute(
      `INSERT INTO emotion_records (employee_id, emotion_type, intensity, trigger, note, recorded_at)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [employeeId, emotionType, intensity || 3, trigger || null, note || null, recordedAt || new Date()]
    );
    return result.insertId;
  }

  /**
   * 获取员工情绪记录列表
   */
  static async findByEmployee(employeeId, { offset = 0, limit = 20, startDate = null, endDate = null, emotionType = null } = {}) {
    const conditions = ['employee_id = ?'];
    const params = [employeeId];

    if (startDate) {
      conditions.push('recorded_at >= ?');
      params.push(startDate);
    }
    if (endDate) {
      conditions.push('recorded_at <= ?');
      params.push(endDate);
    }
    if (emotionType) {
      conditions.push('emotion_type = ?');
      params.push(emotionType);
    }

    const safeOffset = parseInt(offset, 10) || 0;
    const safeLimit = parseInt(limit, 10) || 20;

    const [rows] = await pool.execute(
      `SELECT * FROM emotion_records
       WHERE ${conditions.join(' AND ')}
       ORDER BY recorded_at DESC
       LIMIT ${safeOffset}, ${safeLimit}`,
      params
    );
    return rows;
  }

  /**
   * 标记情绪记录为已处理
   */
  static async markHandled(recordId, { handledBy, note } = {}) {
    const [result] = await pool.execute(
      `UPDATE emotion_records SET handled = 1, handled_at = NOW(), handled_by = ?, note = COALESCE(?, note)
       WHERE id = ?`,
      [handledBy || null, note || null, recordId]
    );
    return result.affectedRows > 0;
  }

  /**
   * 统计员工情绪记录数量
   */
  static async countByEmployee(employeeId, { startDate = null, endDate = null } = {}) {
    const conditions = ['employee_id = ?'];
    const params = [employeeId];

    if (startDate) {
      conditions.push('recorded_at >= ?');
      params.push(startDate);
    }
    if (endDate) {
      conditions.push('recorded_at <= ?');
      params.push(endDate);
    }

    const [rows] = await pool.execute(
      `SELECT COUNT(*) as total FROM emotion_records WHERE ${conditions.join(' AND ')}`,
      params
    );
    return rows[0].total;
  }

  /**
   * 查询消极情绪记录（用于预警列表）
   */
  static async findNegative({ emotions = [], offset = 0, limit = 20, handled } = {}) {
    const safeOffset = parseInt(offset, 10) || 0;
    const safeLimit = parseInt(limit, 10) || 20;
    const placeholders = emotions.map(() => '?').join(',');

    const conditions = [`emotion_type IN (${placeholders})`];
    const params = [...emotions];

    if (handled === false) {
      conditions.push('handled = 0');
    } else if (handled === true) {
      conditions.push('handled = 1');
    }

    const [rows] = await pool.execute(
      `SELECT * FROM emotion_records
       WHERE ${conditions.join(' AND ')}
       ORDER BY recorded_at DESC
       LIMIT ${safeOffset}, ${safeLimit}`,
      params
    );
    return rows;
  }

  /**
   * 获取员工最近N天的情绪记录（用于连续消极情绪检测）
   */
  static async getRecentRecords(employeeId, days = 7) {
    const [rows] = await pool.execute(
      `SELECT * FROM emotion_records
       WHERE employee_id = ? AND recorded_at >= DATE_SUB(CURDATE(), INTERVAL ? DAY)
       ORDER BY recorded_at ASC`,
      [employeeId, days]
    );
    return rows;
  }

  /**
   * 获取情绪统计（按类型分组）
   */
  static async getEmotionStats(employeeId, { startDate = null, endDate = null } = {}) {
    let sql, params;
    if (startDate && endDate) {
      sql = `SELECT emotion_type, COUNT(*) as count, AVG(intensity) as avg_intensity
             FROM emotion_records
             WHERE employee_id = ? AND recorded_at BETWEEN ? AND ?
             GROUP BY emotion_type
             ORDER BY count DESC`;
      params = [employeeId, startDate, endDate];
    } else {
      sql = `SELECT emotion_type, COUNT(*) as count, AVG(intensity) as avg_intensity
             FROM emotion_records
             WHERE employee_id = ?
             GROUP BY emotion_type
             ORDER BY count DESC`;
      params = [employeeId];
    }

    const [rows] = await pool.execute(sql, params);
    return rows;
  }

  /**
   * 获取情绪趋势（按天分组）
   */
  static async getEmotionTrend(employeeId, days = 30) {
    const [rows] = await pool.execute(
      `SELECT DATE(recorded_at) as date,
              COUNT(*) as total_count,
              SUM(CASE WHEN emotion_type IN ('anxious', 'sad', 'angry', 'confused') THEN 1 ELSE 0 END) as negative_count,
              AVG(intensity) as avg_intensity
       FROM emotion_records
       WHERE employee_id = ? AND recorded_at >= DATE_SUB(CURDATE(), INTERVAL ? DAY)
       GROUP BY DATE(recorded_at)
       ORDER BY date ASC`,
      [employeeId, days]
    );
    return rows;
  }
}

module.exports = EmotionRecordModel;
