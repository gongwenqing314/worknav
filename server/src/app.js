/**
 * 工作导航（StepByStep）后端服务 - Express 应用入口
 *
 * 为心智障碍人士提供工作支持的移动应用后端
 */

// 加载环境变量（必须在最前面）
require('dotenv').config();

const express = require('express');
const http = require('http');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const path = require('path');

const config = require('./config');
const logger = require('./utils/logger');
const { notFoundHandler, errorHandler } = require('./middlewares/errorHandler');
const { initWebSocket, getIO } = require('./websocket');

// 创建 Express 应用
const app = express();
const server = http.createServer(app);

// ============================================================
// 中间件配置
// ============================================================

// 安全防护（Helmet）
app.use(helmet({
  contentSecurityPolicy: false, // 允许前端加载各种资源
  crossOriginEmbedderPolicy: false,
}));

// CORS 跨域配置
app.use(cors({
  origin: config.isDev ? '*' : (config.wsCorsOrigin || '*'),
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
  credentials: true,
}));

// 请求体解析
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Gzip 压缩
app.use(compression());

// 静态文件服务（上传文件）
app.use('/uploads', express.static(path.resolve(config.upload.dir)));

// 请求日志（开发环境）
if (config.isDev) {
  app.use((req, res, next) => {
    logger.debug(`${req.method} ${req.originalUrl}`);
    next();
  });
}

// ============================================================
// 根路径处理
// ============================================================

app.get('/', (req, res) => {
  res.json({
    code: 200,
    message: '工作导航（StepByStep）后端服务',
    data: {
      version: '1.0.0',
      apiPrefix: config.apiPrefix,
      healthCheck: `${config.apiPrefix}/health`,
      status: 'running'
    }
  });
});

// ============================================================
// API 路由
// ============================================================

app.use(config.apiPrefix, require('./routes'));

// ============================================================
// 错误处理
// ============================================================

// 404 处理
app.use(notFoundHandler);

// 全局错误处理
app.use(errorHandler);

// ============================================================
// 启动服务
// ============================================================

async function startServer() {
  try {
    // 测试数据库连接
    const dbOk = await config.db.testConnection();
    if (!dbOk) {
      logger.warn('数据库连接失败，服务仍将启动但数据库功能不可用');
    }

    // 测试 Redis 连接（非阻塞）
    config.redis.testConnection().catch(() => {
      logger.warn('Redis 连接失败，缓存和实时功能可能受影响');
    });

    // 初始化 WebSocket
    const io = initWebSocket(server, {
      corsOrigin: config.wsCorsOrigin,
    });

    // 将 WebSocket IO 实例注入到通知服务和远程协助服务
    const notificationService = require('./services/notification.service');
    const remoteAssistService = require('./services/remoteAssist.service');
    notificationService.setWsEmitter(io);
    remoteAssistService.setWsEmitter(io);

    // 启动 HTTP 服务
    server.listen(config.port, () => {
      logger.info('='.repeat(50));
      logger.info(`工作导航（StepByStep）后端服务已启动`);
      logger.info(`环境: ${config.nodeEnv}`);
      logger.info(`端口: ${config.port}`);
      logger.info(`API地址: http://localhost:${config.port}${config.apiPrefix}`);
      logger.info(`健康检查: http://localhost:${config.port}${config.apiPrefix}/health`);
      logger.info('='.repeat(50));
    });

    // 优雅关闭
    process.on('SIGTERM', gracefulShutdown);
    process.on('SIGINT', gracefulShutdown);

  } catch (err) {
    logger.error('服务启动失败:', err);
    process.exit(1);
  }
}

/**
 * 优雅关闭处理
 */
function gracefulShutdown(signal) {
  logger.info(`收到 ${signal} 信号，开始优雅关闭...`);

  // 停止接收新连接
  server.close(() => {
    logger.info('HTTP 服务器已关闭');
  });

  // 关闭 WebSocket
  const io = getIO();
  if (io) {
    io.close(() => {
      logger.info('WebSocket 服务已关闭');
    });
  }

  // 关闭数据库连接池
  config.db.pool.end().then(() => {
    logger.info('数据库连接池已关闭');
    process.exit(0);
  }).catch((err) => {
    logger.error('关闭数据库连接池失败:', err.message);
    process.exit(1);
  });

  // 超时强制退出
  setTimeout(() => {
    logger.warn('优雅关闭超时，强制退出');
    process.exit(1);
  }, 10000);
}

// 启动服务
startServer();

module.exports = { app, server };
