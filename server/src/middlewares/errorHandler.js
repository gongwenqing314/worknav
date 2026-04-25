/**
 * 统一错误处理中间件
 * 捕获所有未处理的错误，返回统一格式的错误响应
 */
const logger = require('../utils/logger');
const { error } = require('../utils/response');

/**
 * 404 处理 - 路由未找到
 */
function notFoundHandler(req, res) {
  return res.status(404).json({
    code: 404,
    message: `接口不存在: ${req.method} ${req.originalUrl}`,
    data: null,
  });
}

/**
 * 全局错误处理中间件
 * 必须放在所有路由之后
 */
function errorHandler(err, req, res, next) {
  // 记录错误日志
  logger.error(`[Error] ${req.method} ${req.originalUrl}`, {
    message: err.message,
    stack: err.stack,
    userId: req.user?.id,
  });

  // 处理不同类型的错误
  if (err.name === 'ValidationError') {
    return res.status(400).json({
      code: 400,
      message: '数据验证失败',
      data: err.errors,
    });
  }

  if (err.name === 'UnauthorizedError') {
    return res.status(401).json({
      code: 401,
      message: '认证失败',
      data: null,
    });
  }

  if (err.name === 'ForbiddenError') {
    return res.status(403).json({
      code: 403,
      message: '无权限',
      data: null,
    });
  }

  if (err.code === 'ER_DUP_ENTRY') {
    return res.status(409).json({
      code: 409,
      message: '数据重复',
      data: null,
    });
  }

  if (err.code === 'ER_NO_REFERENCED_ROW_2') {
    return res.status(400).json({
      code: 400,
      message: '关联数据不存在',
      data: null,
    });
  }

  // Multer 文件上传错误
  if (err.name === 'MulterError') {
    const messages = {
      LIMIT_FILE_SIZE: '文件大小超出限制',
      LIMIT_FILE_COUNT: '文件数量超出限制',
      LIMIT_UNEXPECTED_FILE: '不支持的文件字段',
    };
    return res.status(400).json({
      code: 400,
      message: messages[err.code] || '文件上传失败',
      data: null,
    });
  }

  // 默认返回 500 错误
  const statusCode = err.statusCode || 500;
  const message = process.env.NODE_ENV === 'development'
    ? err.message
    : '服务器内部错误';

  return res.status(statusCode).json({
    code: statusCode,
    message,
    data: process.env.NODE_ENV === 'development' ? err.stack : null,
  });
}

module.exports = { notFoundHandler, errorHandler };
