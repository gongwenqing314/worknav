/**
 * 任务实例模型
 */
const { pool } = require('../config/database');

class TaskInstanceModel {
  /**
   * 根据ID查找任务实例
   */
  static async findById(id) {
    const [rows] = await pool.execute(
      `SELECT ti.*, t.title as template_title, t.description as template_description,
              u.real_name as employee_name, ua.real_name as assigner_name
       FROM task_instances ti
       JOIN task_templates t ON ti.template_id = t.id
       JOIN users u ON ti.employee_id = u.id
       LEFT JOIN users ua ON ti.assigned_by = ua.id
       WHERE ti.id = ?`,
      [id]
    );
    return rows[0] || null;
  }

  /**
   * 获取员工任务列表
   */
  static async findByEmployee(employeeId, { offset = 0, limit = 20, status = null, date = null } = {}) {
    const conditions = ['ti.employee_id = ?'];
    const params = [employeeId];

    if (status) {
      conditions.push('ti.status = ?');
      params.push(status);
    }
    if (date) {
      conditions.push('ti.scheduled_date = ?');
      params.push(date);
    }

    const safeOffset = parseInt(offset, 10) || 0;
    const safeLimit = parseInt(limit, 10) || 20;

    const [rows] = await pool.execute(
      `SELECT ti.*, t.title as template_title, t.cover_image,
              (SELECT COUNT(*) FROM step_executions se WHERE se.instance_id = ti.id AND se.status = 'completed') as completed_steps,
              (SELECT COUNT(*) FROM template_steps ts WHERE ts.template_id = ti.template_id) as total_steps
       FROM task_instances ti
       JOIN task_templates t ON ti.template_id = t.id
       WHERE ${conditions.join(' AND ')}
       ORDER BY ti.scheduled_date DESC, ti.scheduled_time DESC
       LIMIT ${safeOffset}, ${safeLimit}`,
      params
    );
    return rows;
  }

  /**
   * 获取辅导员分配的任务列表
   */
  static async findByCounselor(counselorId, { offset = 0, limit = 20, status = null, date = null } = {}) {
    const conditions = [];
    const params = [];

    // 通过辅导员-员工关联过滤
    conditions.push(`ti.employee_id IN (SELECT employee_id FROM employee_counselor WHERE counselor_id = ?)`);
    params.push(counselorId);

    if (status) {
      conditions.push('ti.status = ?');
      params.push(status);
    }
    if (date) {
      conditions.push('ti.scheduled_date = ?');
      params.push(date);
    }

    const safeOffset = parseInt(offset, 10) || 0;
    const safeLimit = parseInt(limit, 10) || 20;

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
    
    const [rows] = await pool.execute(
      `SELECT ti.*, t.title as template_title, u.real_name as employee_name, u.avatar as employee_avatar
       FROM task_instances ti
       JOIN task_templates t ON ti.template_id = t.id
       JOIN users u ON ti.employee_id = u.id
       ${whereClause}
       ORDER BY ti.scheduled_date DESC, ti.scheduled_time DESC
       LIMIT ${safeOffset}, ${safeLimit}`,
      params
    );
    return rows;
  }

  /**
   * 创建任务实例
   */
  static async create({ templateId, employeeId, assignedBy, scheduledDate, scheduledTime }) {
    const [result] = await pool.execute(
      `INSERT INTO task_instances (template_id, employee_id, assigned_by, scheduled_date, scheduled_time)
       VALUES (?, ?, ?, ?, ?)`,
      [templateId, employeeId, assignedBy || null, scheduledDate || null, scheduledTime || null]
    );
    return result.insertId;
  }

  /**
   * 批量创建任务实例（排班用）
   */
  static async batchCreate(tasks) {
    if (tasks.length === 0) return 0;

    const sql = `
      INSERT INTO task_instances (template_id, employee_id, assigned_by, scheduled_date, scheduled_time)
      VALUES ?
    `;
    const values = tasks.map(t => [t.templateId, t.employeeId, t.assignedBy || null, t.scheduledDate, t.scheduledTime]);

    const [result] = await pool.query(sql, [values]);
    return result.affectedRows;
  }

  /**
   * 更新任务状态
   */
  static async updateStatus(id, status) {
    const fields = { status };
    // 自动设置时间戳
    if (status === 'in_progress') fields.started_at = new Date();
    if (status === 'completed') fields.completed_at = new Date();

    const updates = [];
    const values = [];

    for (const [key, value] of Object.entries(fields)) {
      updates.push(`${key} = ?`);
      values.push(value);
    }

    values.push(id);
    const [result] = await pool.execute(
      `UPDATE task_instances SET ${updates.join(', ')} WHERE id = ?`,
      values
    );
    return result.affectedRows;
  }

  /**
   * 更新任务实例
   */
  static async update(id, fields) {
    const allowedFields = ['status', 'scheduled_date', 'scheduled_time', 'completion_note'];
    const updates = [];
    const values = [];

    for (const key of allowedFields) {
      if (fields[key] !== undefined) {
        updates.push(`${key} = ?`);
        values.push(fields[key]);
      }
    }

    if (updates.length === 0) return 0;

    values.push(id);
    const [result] = await pool.execute(
      `UPDATE task_instances SET ${updates.join(', ')} WHERE id = ?`,
      values
    );
    return result.affectedRows;
  }

  /**
   * 统计员工任务数量
   */
  static async countByEmployee(employeeId, status = null) {
    if (status) {
      const [rows] = await pool.execute(
        'SELECT COUNT(*) as total FROM task_instances WHERE employee_id = ? AND status = ?',
        [employeeId, status]
      );
      return rows[0].total;
    }
    const [rows] = await pool.execute(
      'SELECT COUNT(*) as total FROM task_instances WHERE employee_id = ?',
      [employeeId]
    );
    return rows[0].total;
  }

  /**
   * 获取某日排班任务
   */
  static async findByDate(date, employeeId = null) {
    let sql, params;
    if (employeeId) {
      sql = `SELECT ti.*, t.title as template_title, u.real_name as employee_name
             FROM task_instances ti
             JOIN task_templates t ON ti.template_id = t.id
             JOIN users u ON ti.employee_id = u.id
             WHERE ti.scheduled_date = ? AND ti.employee_id = ?
             ORDER BY ti.scheduled_time ASC`;
      params = [date, employeeId];
    } else {
      sql = `SELECT ti.*, t.title as template_title, u.real_name as employee_name
             FROM task_instances ti
             JOIN task_templates t ON ti.template_id = t.id
             JOIN users u ON ti.employee_id = u.id
             WHERE ti.scheduled_date = ?
             ORDER BY ti.scheduled_time ASC`;
      params = [date];
    }

    const [rows] = await pool.execute(sql, params);
    return rows;
  }
}

module.exports = TaskInstanceModel;
