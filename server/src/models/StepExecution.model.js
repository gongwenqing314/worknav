/**
 * 步骤执行记录模型
 */
const { pool } = require('../config/database');

class StepExecutionModel {
  /**
   * 获取任务实例的所有步骤执行记录
   */
  static async findByInstanceId(instanceId) {
    const [rows] = await pool.execute(
      `SELECT se.*, ts.title as step_title, ts.description as step_description,
              ts.image_url as step_image, ts.tip as step_tip
       FROM step_executions se
       JOIN template_steps ts ON se.step_id = ts.id
       WHERE se.instance_id = ?
       ORDER BY ts.step_order ASC`,
      [instanceId]
    );
    return rows;
  }

  /**
   * 根据ID查找执行记录
   */
  static async findById(id) {
    const [rows] = await pool.execute(
      `SELECT se.*, ts.title as step_title, ts.step_order
       FROM step_executions se
       JOIN template_steps ts ON se.step_id = ts.id
       WHERE se.id = ?`,
      [id]
    );
    return rows[0] || null;
  }

  /**
   * 初始化任务实例的步骤执行记录
   * 根据模板步骤创建对应的执行记录
   */
  static async initFromTemplate(instanceId, templateId) {
    const [steps] = await pool.execute(
      'SELECT id FROM template_steps WHERE template_id = ? ORDER BY step_order ASC',
      [templateId]
    );

    if (steps.length === 0) return 0;

    const sql = `
      INSERT INTO step_executions (instance_id, step_id, status)
      VALUES ?
    `;
    const values = steps.map(s => [instanceId, s.id, 'pending']);
    const [result] = await pool.query(sql, [values]);
    return result.affectedRows;
  }

  /**
   * 更新步骤状态
   */
  static async updateStatus(id, status, { durationSeconds = null, note = null } = {}) {
    const fields = { status };
    const values = [];

    if (status === 'in_progress') {
      fields.started_at = new Date();
    }
    if (status === 'completed') {
      fields.completed_at = new Date();
      fields.duration_seconds = durationSeconds;
    }

    // 增加尝试次数（非 pending 状态时）
    if (status !== 'pending') {
      const [existing] = await pool.execute(
        'SELECT attempt_count FROM step_executions WHERE id = ?',
        [id]
      );
      if (existing.length > 0) {
        fields.attempt_count = existing[0].attempt_count + 1;
      }
    }

    if (note) fields.note = note;

    const updates = [];
    for (const [key, value] of Object.entries(fields)) {
      updates.push(`${key} = ?`);
      values.push(value);
    }

    values.push(id);
    const [result] = await pool.execute(
      `UPDATE step_executions SET ${updates.join(', ')} WHERE id = ?`,
      values
    );
    return result.affectedRows;
  }

  /**
   * 获取步骤耗时统计（用于卡顿热点分析）
   */
  static async getDurationStats(templateId, { startDate = null, endDate = null } = {}) {
    let sql, params;

    if (startDate && endDate) {
      sql = `
        SELECT ts.id as step_id, ts.title as step_title, ts.step_order,
               AVG(se.duration_seconds) as avg_duration,
               MAX(se.duration_seconds) as max_duration,
               MIN(se.duration_seconds) as min_duration,
               COUNT(*) as execution_count,
               SUM(CASE WHEN se.attempt_count > 1 THEN 1 ELSE 0 END) as retry_count
        FROM step_executions se
        JOIN template_steps ts ON se.step_id = ts.id
        JOIN task_instances ti ON se.instance_id = ti.id
        WHERE ts.template_id = ? AND ti.scheduled_date BETWEEN ? AND ?
          AND se.status = 'completed' AND se.duration_seconds IS NOT NULL
        GROUP BY ts.id, ts.title, ts.step_order
        ORDER BY avg_duration DESC
      `;
      params = [templateId, startDate, endDate];
    } else {
      sql = `
        SELECT ts.id as step_id, ts.title as step_title, ts.step_order,
               AVG(se.duration_seconds) as avg_duration,
               MAX(se.duration_seconds) as max_duration,
               MIN(se.duration_seconds) as min_duration,
               COUNT(*) as execution_count,
               SUM(CASE WHEN se.attempt_count > 1 THEN 1 ELSE 0 END) as retry_count
        FROM step_executions se
        JOIN template_steps ts ON se.step_id = ts.id
        WHERE ts.template_id = ? AND se.status = 'completed' AND se.duration_seconds IS NOT NULL
        GROUP BY ts.id, ts.title, ts.step_order
        ORDER BY avg_duration DESC
      `;
      params = [templateId];
    }

    const [rows] = await pool.execute(sql, params);
    return rows;
  }
}

module.exports = StepExecutionModel;
