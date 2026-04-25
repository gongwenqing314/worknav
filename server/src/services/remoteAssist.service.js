/**
 * 远程协助服务
 * 处理远程协助会话的创建、消息收发和标注回传
 */
const AssistSessionModel = require('../models/AssistSession.model');
const AssistMessageModel = require('../models/AssistMessage.model');
const NotificationService = require('./notification.service');
const logger = require('../utils/logger');

// WebSocket 服务引用
let wsEmitter = null;

function setWsEmitter(emitter) {
  wsEmitter = emitter;
}

class RemoteAssistService {
  /**
   * 创建协助请求
   */
  async createSession({ employeeId, requestType, description, photoUrl }) {
    const sessionId = await AssistSessionModel.create({
      employeeId,
      requestType,
      description,
      photoUrl,
    });

    // 通知辅导员
    await NotificationService.sendAssistRequest(employeeId, {
      sessionId,
      description,
    });

    // 通过 WebSocket 广播协助请求
    if (wsEmitter) {
      wsEmitter.emit('assist:request', {
        sessionId,
        employeeId,
        requestType,
        description,
        photoUrl,
        createdAt: new Date().toISOString(),
      });
    }

    logger.info(`创建远程协助请求 (ID: ${sessionId})`);
    return sessionId;
  }

  /**
   * 接听协助请求
   */
  async acceptSession(sessionId, helperId) {
    const affected = await AssistSessionModel.accept(sessionId, helperId);
    if (affected === 0) {
      throw new Error('无法接听：会话不存在或已被接听');
    }

    // 通过 WebSocket 通知员工
    if (wsEmitter) {
      const session = await AssistSessionModel.findById(sessionId);
      wsEmitter.to(`user:${session.employee_id}`).emit('assist:accepted', {
        sessionId,
        helperId,
        acceptedAt: new Date().toISOString(),
      });
    }

    logger.info(`接听远程协助 (会话ID: ${sessionId}, 辅导员ID: ${helperId})`);
  }

  /**
   * 发送消息
   */
  async sendMessage({ sessionId, senderId, senderRole, type, content, fileUrl }) {
    const messageId = await AssistMessageModel.create({
      sessionId,
      senderId,
      senderRole,
      type,
      content,
      fileUrl,
    });

    // 通过 WebSocket 实时推送消息
    if (wsEmitter) {
      const session = await AssistSessionModel.findById(sessionId);
      const room = `assist:${sessionId}`;

      wsEmitter.to(room).emit('assist:message', {
        id: messageId,
        sessionId,
        senderId,
        senderRole,
        type,
        content,
        fileUrl,
        createdAt: new Date().toISOString(),
      });
    }

    return messageId;
  }

  /**
   * 结束协助会话
   */
  async endSession(sessionId, { rating, feedback }) {
    await AssistSessionModel.end(sessionId, { rating, feedback });

    if (wsEmitter) {
      const session = await AssistSessionModel.findById(sessionId);
      wsEmitter.to(`assist:${sessionId}`).emit('assist:ended', {
        sessionId,
        endedAt: new Date().toISOString(),
      });
    }

    logger.info(`结束远程协助 (会话ID: ${sessionId})`);
  }

  /**
   * 上传标注图片
   */
  async uploadAnnotation(sessionId, annotationUrl) {
    await AssistSessionModel.updateAnnotation(sessionId, annotationUrl);

    // 通过 WebSocket 推送标注图片
    if (wsEmitter) {
      wsEmitter.to(`assist:${sessionId}`).emit('assist:annotation', {
        sessionId,
        annotationUrl,
        createdAt: new Date().toISOString(),
      });
    }

    return annotationUrl;
  }

  /**
   * 获取会话消息历史
   */
  async getSessionMessages(sessionId, { offset = 0, limit = 50 } = {}) {
    return AssistMessageModel.findBySession(sessionId, { offset, limit });
  }
}

module.exports = new RemoteAssistService();
module.exports.setWsEmitter = setWsEmitter;
