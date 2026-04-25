/**
 * 通知推送服务
 * 处理消息通知的创建、推送和 WebSocket 实时推送
 */
const NotificationModel = require('../models/Notification.model');
const logger = require('../utils/logger');

// WebSocket 服务引用（在 app.js 中初始化后设置）
let wsEmitter = null;

/**
 * 设置 WebSocket 发射器（由 app.js 调用）
 */
function setWsEmitter(emitter) {
  wsEmitter = emitter;
}

class NotificationService {
  /**
   * 发送通知给单个用户
   */
  async sendToUser(userId, { type, title, content, data }) {
    const notificationId = await NotificationModel.create({
      userId,
      type,
      title,
      content,
      data,
    });

    // 通过 WebSocket 推送
    if (wsEmitter) {
      wsEmitter.to(`user:${userId}`).emit('notification', {
        id: notificationId,
        type,
        title,
        content,
        data,
        created_at: new Date().toISOString(),
      });
    }

    return notificationId;
  }

  /**
   * 批量发送通知给多个用户
   */
  async sendToUsers(userIds, { type, title, content, data }) {
    if (userIds.length === 0) return 0;

    const count = await NotificationModel.batchCreate(userIds, { type, title, content, data });

    // 通过 WebSocket 推送
    if (wsEmitter) {
      const notification = {
        type,
        title,
        content,
        data,
        created_at: new Date().toISOString(),
      };

      for (const userId of userIds) {
        wsEmitter.to(`user:${userId}`).emit('notification', notification);
      }
    }

    return count;
  }

  /**
   * 发送语音加油通知（voice_cheer 类型）
   */
  async sendVoiceCheer(fromUserId, toUserId, { audioUrl, message }) {
    return this.sendToUser(toUserId, {
      type: 'voice_cheer',
      title: '收到一条语音加油',
      content: message || '有人为你加油打气啦！',
      data: {
        fromUserId,
        audioUrl,
        message,
      },
    });
  }

  /**
   * 发送任务分配通知
   */
  async sendTaskAssigned(employeeId, { instanceId, templateTitle, scheduledDate, scheduledTime }) {
    return this.sendToUser(employeeId, {
      type: 'task_assigned',
      title: '新任务分配',
      content: `你有一个新任务「${templateTitle}」${scheduledDate ? `，排班日期: ${scheduledDate}` : ''}`,
      data: { instanceId, templateTitle, scheduledDate, scheduledTime },
    });
  }

  /**
   * 发送任务提醒通知
   */
  async sendTaskReminder(employeeId, { instanceId, templateTitle, scheduledTime }) {
    return this.sendToUser(employeeId, {
      type: 'task_reminder',
      title: '任务提醒',
      content: `任务「${templateTitle}」即将开始${scheduledTime ? `，时间: ${scheduledTime}` : ''}`,
      data: { instanceId, templateTitle, scheduledTime },
    });
  }

  /**
   * 发送远程协助请求通知
   */
  async sendAssistRequest(employeeId, { sessionId, description }) {
    // 获取该员工的辅导员并发送通知
    const EmployeeCounselorModel = require('../models/EmployeeCounselor.model');
    const counselors = await EmployeeCounselorModel.getCounselorsByEmployee(employeeId);
    const counselorIds = counselors.map(c => c.counselor_id);

    if (counselorIds.length > 0) {
      await this.sendToUsers(counselorIds, {
        type: 'assist_request',
        title: '远程协助请求',
        content: `员工请求远程协助${description ? `：${description}` : ''}`,
        data: { sessionId, employeeId },
      });
    }

    return counselorIds.length;
  }

  /**
   * 发送系统通知
   */
  async sendSystemNotification(userId, { title, content }) {
    return this.sendToUser(userId, {
      type: 'system',
      title,
      content,
    });
  }
}

module.exports = new NotificationService();
module.exports.setWsEmitter = setWsEmitter;
