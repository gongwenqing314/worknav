/**
 * 参数校验中间件
 * 基于 express-validator 的请求参数验证
 */
const { validationResult } = require('express-validator');
const { badRequest } = require('../utils/response');

/**
 * 验证结果检查中间件
 * 放在路由的 validate 规则之后使用
 * 如果校验失败，返回 400 错误和详细的错误信息
 */
function validate(req, res, next) {
  const errors = validationResult(req);

  if (!errors.isEmpty()) {
    // 格式化错误信息
    const formattedErrors = errors.array().map(err => ({
      field: err.path,
      message: err.msg,
      value: err.value,
    }));

    return badRequest(res, '请求参数校验失败', formattedErrors);
  }

  next();
}

module.exports = { validate };
