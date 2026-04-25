/**
 * 沟通常用语模型
 */
const { pool } = require('../config/database');

class CommPhraseModel {
  /**
   * 获取分类下的所有常用语（未删除）
   */
  static async findByCategory(categoryId) {
    const [rows] = await pool.execute(
      'SELECT * FROM comm_phrases WHERE category_id = ? AND is_deleted = 0 ORDER BY sort_order ASC',
      [categoryId]
    );
    return rows;
  }

  /**
   * 根据ID查找常用语
   */
  static async findById(id) {
    const [rows] = await pool.execute(
      'SELECT * FROM comm_phrases WHERE id = ? AND is_deleted = 0',
      [id]
    );
    return rows[0] || null;
  }

  /**
   * 创建常用语
   */
  static async create({ categoryId, text, imageUrl, audioUrl, sortOrder }) {
    const [result] = await pool.execute(
      `INSERT INTO comm_phrases (category_id, text, image_url, audio_url, sort_order)
       VALUES (?, ?, ?, ?, ?)`,
      [categoryId, text, imageUrl || null, audioUrl || null, sortOrder || 0]
    );
    return result.insertId;
  }

  /**
   * 批量创建常用语
   */
  static async batchCreate(phrases) {
    if (phrases.length === 0) return 0;

    const sql = `
      INSERT INTO comm_phrases (category_id, text, image_url, audio_url, sort_order)
      VALUES ?
    `;
    const values = phrases.map(p => [p.categoryId, p.text, p.imageUrl || null, p.audioUrl || null, p.sortOrder || 0]);

    const [result] = await pool.query(sql, [values]);
    return result.affectedRows;
  }

  /**
   * 更新常用语
   */
  static async update(id, fields) {
    const allowedFields = ['text', 'image_url', 'audio_url', 'sort_order'];
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
      `UPDATE comm_phrases SET ${updates.join(', ')} WHERE id = ?`,
      values
    );
    return result.affectedRows;
  }

  /**
   * 软删除常用语
   */
  static async softDelete(id) {
    const [result] = await pool.execute(
      'UPDATE comm_phrases SET is_deleted = 1 WHERE id = ?',
      [id]
    );
    return result.affectedRows;
  }

  /**
   * 搜索常用语
   */
  static async search(keyword) {
    const [rows] = await pool.execute(
      `SELECT p.*, c.name as category_name
       FROM comm_phrases p
       JOIN comm_categories c ON p.category_id = c.id
       WHERE p.is_deleted = 0 AND c.is_deleted = 0 AND p.text LIKE ?
       ORDER BY c.sort_order ASC, p.sort_order ASC`,
      [`%${keyword}%`]
    );
    return rows;
  }
}

module.exports = CommPhraseModel;
