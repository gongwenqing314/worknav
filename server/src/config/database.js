/**
 * MySQL 数据库连接配置
 * 使用 mysql2/promise 进行连接池管理
 */
const mysql = require('mysql2/promise');

// 创建数据库连接池
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT, 10) || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'worknav',
  // 连接池配置
  waitForConnections: true,
  connectionLimit: 20,
  queueLimit: 0,
  // 字符集配置
  charset: 'utf8mb4',
  // 时区配置
  timezone: '+08:00',
  // 启用支持 Bigint
  supportBigNumbers: true,
  bigNumberStrings: false,
});

// 测试数据库连接
async function testConnection() {
  try {
    const conn = await pool.getConnection();
    console.log('[MySQL] 数据库连接成功');
    conn.release();
    return true;
  } catch (error) {
    console.error('[MySQL] 数据库连接失败:', error.message);
    return false;
  }
}

module.exports = { pool, testConnection };
