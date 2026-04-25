/**
 * 员工-辅导员关联模型
 */
const { pool } = require('../config/database');

class EmployeeCounselorModel {
  /**
   * 获取员工的所有辅导员
   */
  static async getCounselorsByEmployee(employeeId) {
    const [rows] = await pool.execute(
      `SELECT ec.*, u.real_name, u.phone, u.avatar
       FROM employee_counselor ec
       JOIN users u ON ec.counselor_id = u.id
       WHERE ec.employee_id = ? AND u.status = 1`,
      [employeeId]
    );
    return rows;
  }

  /**
   * 获取辅导员负责的所有员工
   */
  static async getEmployeesByCounselor(counselorId) {
    const [rows] = await pool.execute(
      `SELECT ec.*, u.real_name, u.phone, u.avatar, ep.workplace, ep.job_title
       FROM employee_counselor ec
       JOIN users u ON ec.employee_id = u.id
       LEFT JOIN employee_profiles ep ON ec.employee_id = ep.user_id
       WHERE ec.counselor_id = ? AND u.status = 1`,
      [counselorId]
    );
    return rows;
  }

  /**
   * 添加关联
   */
  static async create(employeeId, counselorId, isPrimary = 0) {
    const [result] = await pool.execute(
      'INSERT INTO employee_counselor (employee_id, counselor_id, is_primary) VALUES (?, ?, ?)',
      [employeeId, counselorId, isPrimary]
    );
    return result.insertId;
  }

  /**
   * 删除关联
   */
  static async delete(employeeId, counselorId) {
    const [result] = await pool.execute(
      'DELETE FROM employee_counselor WHERE employee_id = ? AND counselor_id = ?',
      [employeeId, counselorId]
    );
    return result.affectedRows;
  }

  /**
   * 设置主辅导员
   */
  static async setPrimary(employeeId, counselorId) {
    // 先取消所有主辅导员标记
    await pool.execute(
      'UPDATE employee_counselor SET is_primary = 0 WHERE employee_id = ?',
      [employeeId]
    );
    // 设置新的主辅导员
    const [result] = await pool.execute(
      'UPDATE employee_counselor SET is_primary = 1 WHERE employee_id = ? AND counselor_id = ?',
      [employeeId, counselorId]
    );
    return result.affectedRows;
  }

  /**
   * 检查关联是否存在
   */
  static async exists(employeeId, counselorId) {
    const [rows] = await pool.execute(
      'SELECT id FROM employee_counselor WHERE employee_id = ? AND counselor_id = ?',
      [employeeId, counselorId]
    );
    return rows.length > 0;
  }
}

module.exports = EmployeeCounselorModel;
