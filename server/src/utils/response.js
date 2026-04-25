/**
 * 统一响应格式工具
 * 所有 API 响应都使用此格式：
 * { code: number, message: string, data: any }
 */

/**
 * 成功响应
 * @param {object} res - Express response 对象
 * @param {*} data - 响应数据
 * @param {string} message - 响应消息
 * @param {number} statusCode - HTTP 状态码
 */
function success(res, data = null, message = 'success', statusCode = 200) {
  return res.status(statusCode).json({
    code: statusCode,
    message,
    data,
  });
}

/**
 * 创建成功响应（201）
 * @param {object} res - Express response 对象
 * @param {*} data - 创建的数据
 * @param {string} message - 响应消息
 */
function created(res, data = null, message = '创建成功') {
  return res.status(201).json({
    code: 201,
    message,
    data,
  });
}

/**
 * 错误响应
 * @param {object} res - Express response 对象
 * @param {number} statusCode - HTTP 状态码
 * @param {string} message - 错误消息
 * @param {*} errors - 详细错误信息
 */
function error(res, statusCode = 500, message = '服务器内部错误', errors = null) {
  return res.status(statusCode).json({
    code: statusCode,
    message,
    data: errors,
  });
}

/**
 * 参数校验失败响应（400）
 * @param {object} res - Express response 对象
 * @param {string} message - 错误消息
 * @param {*} errors - 校验错误详情
 */
function badRequest(res, message = '请求参数错误', errors = null) {
  return res.status(400).json({
    code: 400,
    message,
    data: errors,
  });
}

/**
 * 未认证响应（401）
 * @param {object} res - Express response 对象
 * @param {string} message - 错误消息
 */
function unauthorized(res, message = '未认证，请先登录') {
  return res.status(401).json({
    code: 401,
    message,
    data: null,
  });
}

/**
 * 无权限响应（403）
 * @param {object} res - Express response 对象
 * @param {string} message - 错误消息
 */
function forbidden(res, message = '无权限执行此操作') {
  return res.status(403).json({
    code: 403,
    message,
    data: null,
  });
}

/**
 * 资源未找到响应（404）
 * @param {object} res - Express response 对象
 * @param {string} message - 错误消息
 */
function notFound(res, message = '资源不存在') {
  return res.status(404).json({
    code: 404,
    message,
    data: null,
  });
}

module.exports = {
  success,
  created,
  error,
  badRequest,
  unauthorized,
  forbidden,
  notFound,
};
