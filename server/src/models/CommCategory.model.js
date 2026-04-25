/**
 * 沟通板分类模型
 */
const { pool } = require('../config/database');

class CommCategoryModel {
  /**
   * 获取所有分类（未删除）
   */
  static async findAll() {
    const [rows] = await pool.execute(
      `SELECT c.*,
              (SELECT COUNT(*) FROM comm_phrases p WHERE p.category_id = c.id AND p.is_deleted = 0) as phrase_count
       FROM comm_categories c
       WHERE c.is_deleted = 0
       ORDER BY c.sort_order ASC`
    );
    return rows;
  }

  /**
   * 根据ID查找分类
   */
  static async findById(id) {
    const [rows] = await pool.execute(
      'SELECT * FROM comm_categories WHERE id = ? AND is_deleted = 0',
      [id]
    );
    return rows[0] || null;
  }

  /**
   * 创建分类
   */
  static async create({ name, icon, sortOrder, createdBy }) {
    const [result] = await pool.execute(
      'INSERT INTO comm_categories (name, icon, sort_order, created_by) VALUES (?, ?, ?, ?)',
      [name, icon || null, sortOrder || 0, createdBy || null]
    );
    return result.insertId;
  }

  /**
   * 更新分类
   */
  static async update(id, fields) {
    const allowedFields = ['name', 'icon', 'sort_order'];
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
      `UPDATE comm_categories SET ${updates.join(', ')} WHERE id = ?`,
      values
    );
    return result.affectedRows;
  }

  /**
   * 软删除分类
   */
  static async softDelete(id) {
    const [result] = await pool.execute(
      'UPDATE comm_categories SET is_deleted = 1 WHERE id = ?',
      [id]
    );
    return result.affectedRows;
  }
}

module.exports = CommCategoryModel;
