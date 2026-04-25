/**
 * 情绪预警规则模型
 */
const { pool } = require('../config/database');

class EmotionAlertRuleModel {
  /**
   * 获取所有活跃的预警规则
   */
  static async findActiveRules() {
    const [rows] = await pool.execute(
      'SELECT * FROM emotion_alert_rules WHERE is_active = 1'
    );
    return rows;
  }

  /**
   * 获取指定员工的预警规则（个人 + 全局）
   */
  static async findByEmployee(employeeId) {
    const [rows] = await pool.execute(
      'SELECT * FROM emotion_alert_rules WHERE (employee_id = ? OR employee_id IS NULL) AND is_active = 1',
      [employeeId]
    );
    return rows;
  }

  /**
   * 创建预警规则
   */
  static async create({ employeeId, negativeTypes, consecutiveDays, minIntensity, notifyCounselor, notifyParent }) {
    const [result] = await pool.execute(
      `INSERT INTO emotion_alert_rules (employee_id, negative_types, consecutive_days, min_intensity, notify_counselor, notify_parent)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [employeeId || null, JSON.stringify(negativeTypes), consecutiveDays || 3, minIntensity || 3, notifyCounselor !== undefined ? notifyCounselor : 1, notifyParent !== undefined ? notifyParent : 1]
    );
    return result.insertId;
  }

  /**
   * 更新预警规则
   */
  static async update(id, fields) {
    const allowedFields = ['negative_types', 'consecutive_days', 'min_intensity', 'notify_counselor', 'notify_parent', 'is_active'];
    const updates = [];
    const values = [];

    for (const key of allowedFields) {
      if (fields[key] !== undefined) {
        // negative_types 需要转为 JSON 字符串
        if (key === 'negative_types' && Array.isArray(fields[key])) {
          updates.push(`${key} = ?`);
          values.push(JSON.stringify(fields[key]));
        } else {
          updates.push(`${key} = ?`);
          values.push(fields[key]);
        }
      }
    }

    if (updates.length === 0) return 0;

    values.push(id);
    const [result] = await pool.execute(
      `UPDATE emotion_alert_rules SET ${updates.join(', ')} WHERE id = ?`,
      values
    );
    return result.affectedRows;
  }

  /**
   * 删除预警规则
   */
  static async delete(id) {
    const [result] = await pool.execute(
      'DELETE FROM emotion_alert_rules WHERE id = ?',
      [id]
    );
    return result.affectedRows;
  }
}

module.exports = EmotionAlertRuleModel;
