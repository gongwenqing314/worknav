/**
 * 模板步骤模型
 */
const { pool } = require('../config/database');

class TemplateStepModel {
  /**
   * 获取模板的所有步骤（按顺序）
   */
  static async findByTemplateId(templateId) {
    const [rows] = await pool.execute(
      'SELECT * FROM template_steps WHERE template_id = ? ORDER BY step_order ASC',
      [templateId]
    );
    return rows;
  }

  /**
   * 根据ID查找步骤
   */
  static async findById(id) {
    const [rows] = await pool.execute(
      'SELECT * FROM template_steps WHERE id = ?',
      [id]
    );
    return rows[0] || null;
  }

  /**
   * 创建步骤
   */
  static async create({ templateId, stepOrder, title, description, imageUrl, audioUrl, tip, estimatedSeconds }) {
    const [result] = await pool.execute(
      `INSERT INTO template_steps (template_id, step_order, title, description, image_url, audio_url, tip, estimated_seconds)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [templateId, stepOrder, title, description || null, imageUrl || null, audioUrl || null, tip || null, estimatedSeconds || null]
    );
    return result.insertId;
  }

  /**
   * 批量创建步骤
   */
  static async batchCreate(steps) {
    if (steps.length === 0) return;

    const sql = `
      INSERT INTO template_steps (template_id, step_order, title, description, image_url, audio_url, tip, estimated_seconds)
      VALUES ?
    `;
    const values = steps.map(s => [
      s.templateId, s.stepOrder, s.title, s.description || null,
      s.imageUrl || null, s.audioUrl || null, s.tip || null, s.estimatedSeconds || null
    ]);

    const [result] = await pool.query(sql, [values]);
    return result.affectedRows;
  }

  /**
   * 更新步骤
   */
  static async update(id, fields) {
    const allowedFields = ['step_order', 'title', 'description', 'image_url', 'audio_url', 'tip', 'estimated_seconds'];
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
      `UPDATE template_steps SET ${updates.join(', ')} WHERE id = ?`,
      values
    );
    return result.affectedRows;
  }

  /**
   * 删除步骤
   */
  static async delete(id) {
    const [result] = await pool.execute(
      'DELETE FROM template_steps WHERE id = ?',
      [id]
    );
    return result.affectedRows;
  }

  /**
   * 删除模板的所有步骤
   */
  static async deleteByTemplateId(templateId) {
    const [result] = await pool.execute(
      'DELETE FROM template_steps WHERE template_id = ?',
      [templateId]
    );
    return result.affectedRows;
  }

  /**
   * 获取模板步骤总数
   */
  static async countByTemplateId(templateId) {
    const [rows] = await pool.execute(
      'SELECT COUNT(*) as total FROM template_steps WHERE template_id = ?',
      [templateId]
    );
    return rows[0].total;
  }
}

module.exports = TemplateStepModel;
