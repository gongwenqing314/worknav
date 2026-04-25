/**
 * 用户模型
 * 提供用户表的 CRUD 操作
 */
const { pool } = require('../config/database');

class UserModel {
  /**
   * 根据ID查找用户
   */
  static async findById(id) {
    const [rows] = await pool.execute(
      'SELECT id, username, real_name, phone, avatar, role, status, last_login_at, created_at, updated_at FROM users WHERE id = ?',
      [id]
    );
    return rows[0] || null;
  }

  /**
   * 根据用户名查找用户（包含密码哈希，用于登录验证）
   */
  static async findByUsername(username) {
    const [rows] = await pool.execute(
      'SELECT * FROM users WHERE username = ?',
      [username]
    );
    return rows[0] || null;
  }

  /**
   * 根据手机号查找用户（包含密码哈希，用于登录验证）
   */
  static async findByPhone(phone) {
    const [rows] = await pool.execute(
      'SELECT * FROM users WHERE phone = ?',
      [phone]
    );
    return rows[0] || null;
  }

  /**
   * 根据角色查找用户列表
   */
  static async findByRole(role, { offset = 0, limit = 20 } = {}) {
    const safeOffset = parseInt(offset, 10) || 0;
    const safeLimit = parseInt(limit, 10) || 20;
    const [rows] = await pool.execute(
      `SELECT id, username, real_name, phone, avatar, role, status, created_at FROM users WHERE role = ? LIMIT ${safeOffset}, ${safeLimit}`,
      [role]
    );
    return rows;
  }

  /**
   * 创建新用户
   */
  static async create({ username, passwordHash, realName, phone, avatar, role, status, gender, birthDate }) {
    const [result] = await pool.execute(
      'INSERT INTO users (username, password_hash, real_name, phone, avatar, role, status, gender, birth_date) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [username, passwordHash, realName, phone || null, avatar || null, role, status !== undefined ? status : 1, gender || null, birthDate || null]
    );
    return result.insertId;
  }

  /**
   * 更新用户信息
   */
  static async update(id, fields) {
    const allowedFields = ['realName', 'phone', 'avatar', 'status', 'gender', 'birthDate'];
    const updates = [];
    const values = [];

    for (const [key, value] of Object.entries(fields)) {
      if (allowedFields.includes(key) && value !== undefined) {
        // 将驼峰命名转为下划线命名
        const dbKey = key.replace(/([A-Z])/g, '_$1').toLowerCase();
        updates.push(`${dbKey} = ?`);
        // 日期格式转换：ISO 8601 -> YYYY-MM-DD
        let processedValue = value;
        if (key === 'birthDate' && typeof value === 'string' && value.includes('T')) {
          processedValue = value.split('T')[0];
        }
        values.push(processedValue);
      }
    }

    if (updates.length === 0) return 0;

    values.push(id);
    const [result] = await pool.execute(
      `UPDATE users SET ${updates.join(', ')} WHERE id = ?`,
      values
    );
    return result.affectedRows;
  }

  /**
   * 更新最后登录时间
   */
  static async updateLastLogin(id) {
    const [result] = await pool.execute(
      'UPDATE users SET last_login_at = NOW() WHERE id = ?',
      [id]
    );
    return result.affectedRows;
  }

  /**
   * 修改密码
   */
  static async updatePassword(id, passwordHash) {
    const [result] = await pool.execute(
      'UPDATE users SET password_hash = ? WHERE id = ?',
      [passwordHash, id]
    );
    return result.affectedRows;
  }

  /**
   * 删除用户（软删除，设置状态为禁用）
   */
  static async delete(id) {
    const [result] = await pool.execute(
      'UPDATE users SET status = 0 WHERE id = ?',
      [id]
    );
    return result.affectedRows;
  }

  /**
   * 获取用户总数
   */
  static async count(role = null) {
    if (role) {
      const [rows] = await pool.execute(
        'SELECT COUNT(*) as total FROM users WHERE role = ? AND status = 1',
        [role]
      );
      return rows[0].total;
    }
    const [rows] = await pool.execute(
      'SELECT COUNT(*) as total FROM users WHERE status = 1'
    );
    return rows[0].total;
  }
}

module.exports = UserModel;
