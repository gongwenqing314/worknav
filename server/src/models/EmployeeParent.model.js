/**
 * 员工-家长关联模型
 * 包含审核流程
 */
const { pool } = require('../config/database');

class EmployeeParentModel {
  /**
   * 获取员工的所有家长
   */
  static async getParentsByEmployee(employeeId) {
    const [rows] = await pool.execute(
      `SELECT ep.*, u.real_name, u.phone, u.avatar
       FROM employee_parent ep
       JOIN users u ON ep.parent_id = u.id
       WHERE ep.employee_id = ? AND ep.status = 'approved'`,
      [employeeId]
    );
    return rows;
  }

  /**
   * 获取家长关联的所有员工
   */
  static async getEmployeesByParent(parentId) {
    const [rows] = await pool.execute(
      `SELECT ep.*, u.real_name, u.phone, u.avatar, epf.workplace, epf.job_title
       FROM employee_parent ep
       JOIN users u ON ep.employee_id = u.id
       LEFT JOIN employee_profiles epf ON ep.employee_id = epf.user_id
       WHERE ep.parent_id = ? AND ep.status = 'approved' AND u.status = 1`,
      [parentId]
    );
    return rows;
  }

  /**
   * 发起家长关联请求
   */
  static async create(employeeId, parentId, relation = null) {
    const [result] = await pool.execute(
      'INSERT INTO employee_parent (employee_id, parent_id, relation) VALUES (?, ?, ?)',
      [employeeId, parentId, relation]
    );
    return result.insertId;
  }

  /**
   * 审核家长关联请求
   */
  static async review(id, status) {
    const [result] = await pool.execute(
      'UPDATE employee_parent SET status = ? WHERE id = ?',
      [status, id]
    );
    return result.affectedRows;
  }

  /**
   * 获取待审核的关联请求
   */
  static async getPendingRequests(employeeId) {
    const [rows] = await pool.execute(
      `SELECT ep.*, u.real_name, u.phone, u.avatar
       FROM employee_parent ep
       JOIN users u ON ep.parent_id = u.id
       WHERE ep.employee_id = ? AND ep.status = 'pending'`,
      [employeeId]
    );
    return rows;
  }

  /**
   * 删除关联
   */
  static async delete(employeeId, parentId) {
    const [result] = await pool.execute(
      'DELETE FROM employee_parent WHERE employee_id = ? AND parent_id = ?',
      [employeeId, parentId]
    );
    return result.affectedRows;
  }

  /**
   * 检查已审核通过的关联是否存在
   */
  static async existsApproved(employeeId, parentId) {
    const [rows] = await pool.execute(
      "SELECT id FROM employee_parent WHERE employee_id = ? AND parent_id = ? AND status = 'approved'",
      [employeeId, parentId]
    );
    return rows.length > 0;
  }
}

module.exports = EmployeeParentModel;
