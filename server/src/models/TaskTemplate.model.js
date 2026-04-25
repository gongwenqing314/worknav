/**
 * 任务模板模型
 */
const { pool } = require('../config/database');

class TaskTemplateModel {
  /**
   * 根据ID查找模板（含步骤）
   */
  static async findById(id) {
    const [rows] = await pool.execute(
      'SELECT * FROM task_templates WHERE id = ?',
      [id]
    );
    return rows[0] || null;
  }

  /**
   * 获取模板详情（含步骤列表）
   */
  static async findByIdWithSteps(id) {
    const [templates] = await pool.execute(
      'SELECT * FROM task_templates WHERE id = ?',
      [id]
    );
    if (templates.length === 0) return null;

    const [steps] = await pool.execute(
      'SELECT * FROM template_steps WHERE template_id = ? ORDER BY step_order ASC',
      [id]
    );

    return {
      ...templates[0],
      steps,
    };
  }

  /**
   * 获取模板列表
   */
  static async findAll({ offset = 0, limit = 20, creatorId = null, category = null, isPublic = null } = {}) {
    const conditions = [];
    const params = [];

    if (creatorId) {
      conditions.push('t.creator_id = ?');
      params.push(creatorId);
    }
    if (category) {
      conditions.push('t.category = ?');
      params.push(category);
    }
    if (isPublic !== null) {
      conditions.push('t.is_public = ?');
      params.push(isPublic);
    }
    conditions.push('t.status = 1');

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    const safeOffset = parseInt(offset, 10) || 0;
    const safeLimit = parseInt(limit, 10) || 20;

    const [rows] = await pool.execute(
      `SELECT t.*, u.real_name as creator_name,
              (SELECT COUNT(*) FROM template_steps ts WHERE ts.template_id = t.id) as step_count
       FROM task_templates t
       JOIN users u ON t.creator_id = u.id
       ${whereClause}
       ORDER BY t.updated_at DESC
       LIMIT ${safeOffset}, ${safeLimit}`,
      params
    );
    return rows;
  }

  /**
   * 统计模板数量
   */
  static async count({ creatorId = null, category = null, isPublic = null } = {}) {
    const conditions = ['status = 1'];
    const params = [];

    if (creatorId) {
      conditions.push('creator_id = ?');
      params.push(creatorId);
    }
    if (category) {
      conditions.push('category = ?');
      params.push(category);
    }
    if (isPublic !== null) {
      conditions.push('is_public = ?');
      params.push(isPublic);
    }

    const [rows] = await pool.execute(
      `SELECT COUNT(*) as total FROM task_templates WHERE ${conditions.join(' AND ')}`,
      params
    );
    return rows[0].total;
  }

  /**
   * 创建任务模板
   */
  static async create({ creatorId, title, description, coverImage, category, isPublic, estimatedMinutes }) {
    const [result] = await pool.execute(
      `INSERT INTO task_templates (creator_id, title, description, cover_image, category, is_public, estimated_minutes)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [creatorId, title, description || null, coverImage || null, category || null, isPublic || 0, estimatedMinutes || null]
    );
    return result.insertId;
  }

  /**
   * 更新任务模板
   */
  static async update(id, fields) {
    const allowedFields = ['title', 'description', 'cover_image', 'category', 'is_public', 'status', 'estimated_minutes'];
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
      `UPDATE task_templates SET ${updates.join(', ')} WHERE id = ?`,
      values
    );
    return result.affectedRows;
  }

  /**
   * 删除任务模板
   */
  static async delete(id) {
    const [result] = await pool.execute(
      'DELETE FROM task_templates WHERE id = ?',
      [id]
    );
    return result.affectedRows;
  }
}

module.exports = TaskTemplateModel;
