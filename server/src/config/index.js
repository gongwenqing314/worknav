/**
 * 统一配置导出
 * 汇总所有配置模块，提供统一入口
 */

const database = require('./database');
const redis = require('./redis');
const jwt = require('./jwt');

// 应用基础配置
const appConfig = {
  port: parseInt(process.env.PORT, 10) || 3000,
  nodeEnv: process.env.NODE_ENV || 'development',
  isDev: (process.env.NODE_ENV || 'development') === 'development',
  // API 版本前缀
  apiPrefix: '/api/v1',
  // 文件上传配置
  upload: {
    dir: process.env.UPLOAD_DIR || './uploads',
    maxFileSize: parseInt(process.env.MAX_FILE_SIZE, 10) || 10 * 1024 * 1024, // 10MB
  },
  // WebSocket CORS 配置
  wsCorsOrigin: process.env.WS_CORS_ORIGIN || 'http://localhost:3001',
};

module.exports = {
  ...appConfig,
  db: database,
  redis,
  jwt,
};
