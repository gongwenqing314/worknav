/**
 * 消息通知控制器
 * 处理通知的查询、标记已读和发送语音加油
 */
const NotificationModel = require('../models/Notification.model');
const notificationService = require('../services/notification.service');
const { success, notFound } = require('../utils/response');
const { parsePagination, paginationMeta } = require('../utils/helpers');

class NotificationController {
  /**
   * 获取通知列表
   * GET /api/v1/notifications
   */
  async list(req, res, next) {
    try {
      const { type, isRead } = req.query;
      const { offset, limit, page, pageSize } = parsePagination(req.query);

      const notifications = await NotificationModel.findByUser(req.user.id, {
        offset, limit,
        type,
        isRead: isRead !== undefined ? parseInt(isRead) : undefined,
      });

      return success(res, {
        list: notifications,
        pagination: paginationMeta(notifications.length, page, pageSize),
      });
    } catch (err) {
      next(err);
    }
  }

  /**
   * 获取未读通知数量
   * GET /api/v1/notifications/unread-count
   */
  async getUnreadCount(req, res, next) {
    try {
      const count = await NotificationModel.getUnreadCount(req.user.id);
      return success(res, { count });
    } catch (err) {
      next(err);
    }
  }

  /**
   * 标记通知为已读
   * PUT /api/v1/notifications/:notificationId/read
   */
  async markAsRead(req, res, next) {
    try {
      const affected = await NotificationModel.markAsRead(req.params.notificationId, req.user.id);
      if (affected === 0) {
        return notFound(res, '通知不存在');
      }
      return success(res, null, '已标记为已读');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 全部标记为已读
   * PUT /api/v1/notifications/read-all
   */
  async markAllAsRead(req, res, next) {
    try {
      const affected = await NotificationModel.markAllAsRead(req.user.id);
      return success(res, { count: affected }, `已将${affected}条通知标记为已读`);
    } catch (err) {
      next(err);
    }
  }

  /**
   * 删除通知
   * DELETE /api/v1/notifications/:notificationId
   */
  async delete(req, res, next) {
    try {
      await NotificationModel.delete(req.params.notificationId, req.user.id);
      return success(res, null, '通知已删除');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 发送语音加油
   * POST /api/v1/notifications/voice-cheer
   */
  async sendVoiceCheer(req, res, next) {
    try {
      const { toUserId, audioUrl, message } = req.body;

      if (!toUserId) {
        return res.status(400).json({ code: 400, message: '请指定接收用户', data: null });
      }

      const notificationId = await notificationService.sendVoiceCheer(
        req.user.id,
        toUserId,
        { audioUrl, message }
      );

      return success(res, { notificationId }, '语音加油已发送');
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new NotificationController();
