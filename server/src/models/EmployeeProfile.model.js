/**
 * 员工档案模型
 */
const { pool } = require('../config/database');

class EmployeeProfileModel {
  /**
   * 根据用户ID查找档案
   */
  static async findByUserId(userId) {
    const [rows] = await pool.execute(
      'SELECT * FROM employee_profiles WHERE user_id = ?',
      [userId]
    );
    return rows[0] || null;
  }

  /**
   * 创建员工档案
   */
  static async create({ userId, disabilityType, supportLevel, workplace, jobTitle, emergencyContact, emergencyPhone, notes }) {
    const [result] = await pool.execute(
      `INSERT INTO employee_profiles (user_id, disability_type, support_level, workplace, job_title, emergency_contact, emergency_phone, notes)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [userId, disabilityType || null, supportLevel || null, workplace || null, jobTitle || null, emergencyContact || null, emergencyPhone || null, notes || null]
    );
    return result.insertId;
  }

  /**
   * 更新员工档案
   */
  static async update(userId, fields) {
    const allowedFields = ['disability_type', 'support_level', 'workplace', 'job_title', 'emergency_contact', 'emergency_phone', 'notes', 'group_id'];
    const updates = [];
    const values = [];

    for (const key of allowedFields) {
      if (fields[key] !== undefined) {
        updates.push(`${key} = ?`);
        values.push(fields[key] === null ? null : fields[key]);
      }
    }

    if (updates.length === 0) return 0;

    values.push(userId);
    const [result] = await pool.execute(
      `UPDATE employee_profiles SET ${updates.join(', ')} WHERE user_id = ?`,
      values
    );
    return result.affectedRows;
  }

  /**
   * 获取员工列表（含用户基本信息）
   */
  static async findAll({ offset = 0, limit = 20, counselorId = null } = {}) {
    try {
      const safeOffset = parseInt(offset, 10) || 0;
      const safeLimit = parseInt(limit, 10) || 20;
      const sql = `
        SELECT 
          u.id,
          u.id as user_id,
          u.username,
          u.real_name as name,
          u.gender,
          u.birth_date as birthDate,
          u.phone,
          u.avatar,
          u.status,
          ep.disability_type as disabilityType,
          ep.group_id as groupId,
          eg.name as groupName,
          ep.support_level as supportLevel,
          ep.workplace,
          ep.job_title as jobTitle,
          ep.emergency_contact as guardianName,
          ep.emergency_phone as guardianPhone,
          ep.notes as remark,
          TIMESTAMPDIFF(YEAR, u.birth_date, CURDATE()) as age
        FROM users u
        LEFT JOIN employee_profiles ep ON u.id = ep.user_id
        LEFT JOIN employee_groups eg ON ep.group_id = eg.id
        WHERE u.role = 'employee'
        LIMIT ${safeOffset}, ${safeLimit}
      `;

      const [rows] = await pool.execute(sql);
      return rows;
    } catch (error) {
      console.error('获取员工列表失败:', error.message);
      return [];
    }
  }

  /**
   * 统计员工总数
   */
  static async count(counselorId = null) {
    try {
      const [rows] = await pool.execute(
        `SELECT COUNT(*) as total FROM users WHERE role = 'employee'`
      );
      return rows[0].total;
    } catch (error) {
      console.error('统计员工总数失败:', error.message);
      return 0;
    }
  }
}

module.exports = EmployeeProfileModel;
