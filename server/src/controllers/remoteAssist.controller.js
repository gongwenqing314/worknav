/**
 * 远程协助控制器
 * 处理远程协助会话的创建、接听、消息收发和标注回传
 */
const remoteAssistService = require('../services/remoteAssist.service');
const AssistSessionModel = require('../models/AssistSession.model');
const { success, created, notFound } = require('../utils/response');
const { parsePagination, paginationMeta } = require('../utils/helpers');
const { upload, getFileUrl } = require('../services/file.service');

class RemoteAssistController {
  /**
   * 创建协助请求
   * POST /api/v1/remote-assist/sessions
   */
  async createSession(req, res, next) {
    try {
      const { requestType, description } = req.body;

      // 如果有上传照片
      let photoUrl = null;
      if (req.file) {
        photoUrl = getFileUrl(req.file.filename, 'images');
      }

      const sessionId = await remoteAssistService.createSession({
        employeeId: req.user.id,
        requestType,
        description,
        photoUrl,
      });

      return created(res, { sessionId }, '协助请求已发送');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 获取待接听的协助请求列表
   * GET /api/v1/remote-assist/sessions/pending
   */
  async listPendingSessions(req, res, next) {
    try {
      const sessions = await AssistSessionModel.findPendingSessions();
      return success(res, sessions);
    } catch (err) {
      next(err);
    }
  }

  /**
   * 获取协助会话列表
   * GET /api/v1/remote-assist/sessions
   */
  async listSessions(req, res, next) {
    try {
      const { status } = req.query;
      const { offset, limit, page, pageSize } = parsePagination(req.query);

      let sessions;
      if (req.user.role === 'employee') {
        sessions = await AssistSessionModel.findByEmployee(req.user.id, { offset, limit, status });
      } else {
        sessions = await AssistSessionModel.findByHelper(req.user.id, { offset, limit, status });
      }

      return success(res, {
        list: sessions,
        pagination: paginationMeta(sessions.length, page, pageSize),
      });
    } catch (err) {
      next(err);
    }
  }

  /**
   * 获取会话详情
   * GET /api/v1/remote-assist/sessions/:sessionId
   */
  async getSession(req, res, next) {
    try {
      const session = await AssistSessionModel.findById(req.params.sessionId);
      if (!session) {
        return notFound(res, '会话不存在');
      }

      // 附带消息历史
      session.messages = await remoteAssistService.getSessionMessages(req.params.sessionId);

      return success(res, session);
    } catch (err) {
      next(err);
    }
  }

  /**
   * 接听协助请求
   * POST /api/v1/remote-assist/sessions/:sessionId/accept
   */
  async acceptSession(req, res, next) {
    try {
      await remoteAssistService.acceptSession(req.params.sessionId, req.user.id);
      return success(res, null, '已接听协助请求');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 发送消息
   * POST /api/v1/remote-assist/sessions/:sessionId/messages
   */
  async sendMessage(req, res, next) {
    try {
      const { type, content } = req.body;

      // 如果有上传文件
      let fileUrl = null;
      if (req.file) {
        const subDir = type === 'voice' ? 'audio' : 'images';
        fileUrl = getFileUrl(req.file.filename, subDir);
      }

      const messageId = await remoteAssistService.sendMessage({
        sessionId: req.params.sessionId,
        senderId: req.user.id,
        senderRole: req.user.role === 'employee' ? 'employee' : 'counselor',
        type,
        content,
        fileUrl,
      });

      return created(res, { messageId }, '消息已发送');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 获取会话消息历史
   * GET /api/v1/remote-assist/sessions/:sessionId/messages
   */
  async getMessages(req, res, next) {
    try {
      const { offset, limit } = parsePagination(req.query);
      const messages = await remoteAssistService.getSessionMessages(req.params.sessionId, { offset, limit });
      return success(res, messages);
    } catch (err) {
      next(err);
    }
  }

  /**
   * 上传标注图片
   * POST /api/v1/remote-assist/sessions/:sessionId/annotation
   */
  async uploadAnnotation(req, res, next) {
    try {
      if (!req.file) {
        return res.status(400).json({ code: 400, message: '请上传标注图片', data: null });
      }

      const annotationUrl = getFileUrl(req.file.filename, 'annotations');
      await remoteAssistService.uploadAnnotation(req.params.sessionId, annotationUrl);

      return success(res, { annotationUrl }, '标注图片已上传');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 结束协助会话
   * POST /api/v1/remote-assist/sessions/:sessionId/end
   */
  async endSession(req, res, next) {
    try {
      const { rating, feedback } = req.body;
      await remoteAssistService.endSession(req.params.sessionId, { rating, feedback });
      return success(res, null, '协助会话已结束');
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new RemoteAssistController();
module.exports.uploadMiddleware = upload.single('photo');
module.exports.messageUploadMiddleware = upload.single('file');
module.exports.annotationUploadMiddleware = upload.single('annotation');
