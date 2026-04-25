/**
 * WebSocket 服务入口
 * 初始化 Socket.IO 并注册消息处理器
 */
const { Server } = require('socket.io');
const { handleConnection } = require('./handlers');
const logger = require('../utils/logger');

let io = null;

/**
 * 初始化 WebSocket 服务
 * @param {import('http').Server} httpServer - HTTP 服务器实例
 * @param {object} options - 配置选项
 * @returns {Server} Socket.IO 实例
 */
function initWebSocket(httpServer, options = {}) {
  io = new Server(httpServer, {
    cors: {
      origin: options.corsOrigin || 'http://localhost:3001',
      methods: ['GET', 'POST'],
      credentials: true,
    },
    // 传输方式配置
    transports: ['websocket', 'polling'],
    // ping 超时和间隔
    pingTimeout: 60000,
    pingInterval: 25000,
  });

  // 注册连接处理器
  io.on('connection', (socket) => {
    handleConnection(io, socket);
  });

  logger.info('[WebSocket] 服务已启动');

  return io;
}

/**
 * 获取 IO 实例
 */
function getIO() {
  return io;
}

module.exports = { initWebSocket, getIO };
