/**
 * WebSocket 消息处理器
 * 处理各种 WebSocket 事件
 */
const { verifyAccessToken } = require('../config/jwt');
const logger = require('../utils/logger');
const syncService = require('../services/sync.service');

/**
 * 处理客户端连接
 */
function handleConnection(io, socket) {
  logger.info(`[WebSocket] 新连接: ${socket.id}`);

  // 身份认证
  socket.on('auth', async (token) => {
    try {
      const decoded = verifyAccessToken(token);
      socket.user = decoded;

      // 加入用户专属房间
      socket.join(`user:${decoded.userId}`);

      // 如果是辅导员，加入辅导员房间（用于接收协助请求）
      if (['counselor', 'co_counselor'].includes(decoded.role)) {
        socket.join('counselors');
      }

      logger.info(`[WebSocket] 用户认证成功: ${decoded.username} (${socket.id})`);
      socket.emit('auth:success', { userId: decoded.userId, username: decoded.username });
    } catch (err) {
      logger.warn(`[WebSocket] 认证失败: ${socket.id}`);
      socket.emit('auth:error', { message: '认证失败' });
    }
  });

  // 加入协助会话房间
  socket.on('assist:join', (sessionId) => {
    if (!socket.user) {
      socket.emit('error', { message: '请先认证' });
      return;
    }
    socket.join(`assist:${sessionId}`);
    logger.info(`[WebSocket] 加入协助房间: ${sessionId}, 用户: ${socket.user.userId}`);
  });

  // 离开协助会话房间
  socket.on('assist:leave', (sessionId) => {
    socket.leave(`assist:${sessionId}`);
    logger.info(`[WebSocket] 离开协助房间: ${sessionId}`);
  });

  // 接收实时消息
  socket.on('assist:message', async (data) => {
    if (!socket.user) {
      socket.emit('error', { message: '请先认证' });
      return;
    }

    try {
      const remoteAssistService = require('../services/remoteAssist.service');
      await remoteAssistService.sendMessage({
        sessionId: data.sessionId,
        senderId: socket.user.userId,
        senderRole: socket.user.role === 'employee' ? 'employee' : 'counselor',
        type: data.type || 'text',
        content: data.content,
        fileUrl: data.fileUrl,
      });
    } catch (err) {
      logger.error(`[WebSocket] 发送消息失败:`, err.message);
      socket.emit('error', { message: '消息发送失败' });
    }
  });

  // 离线数据同步
  socket.on('sync:upload', async (data) => {
    if (!socket.user) {
      socket.emit('error', { message: '请先认证' });
      return;
    }

    try {
      const { deviceId, operations } = data;
      const results = await syncService.uploadOfflineData(socket.user.userId, deviceId, operations);
      socket.emit('sync:upload:result', results);
    } catch (err) {
      logger.error(`[WebSocket] 同步上传失败:`, err.message);
      socket.emit('error', { message: '同步失败' });
    }
  });

  // 心跳检测
  socket.on('ping', () => {
    socket.emit('pong');
  });

  // 断开连接
  socket.on('disconnect', () => {
    logger.info(`[WebSocket] 断开连接: ${socket.id}`);
  });
}

module.exports = { handleConnection };
