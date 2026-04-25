/**
 * 辅助函数工具集
 */

/**
 * 分页参数解析
 * 将 query 中的 page/pageSize 转换为 offset/limit
 * @param {object} query - Express request.query
 * @returns {{ page: number, pageSize: number, offset: number, limit: number }}
 */
function parsePagination(query) {
  const page = Math.max(1, parseInt(query.page, 10) || 1);
  const pageSize = Math.min(100, Math.max(1, parseInt(query.pageSize, 10) || 20));
  return {
    page,
    pageSize,
    offset: (page - 1) * pageSize,
    limit: pageSize,
  };
}

/**
 * 生成分页响应元数据
 * @param {number} total - 总记录数
 * @param {number} page - 当前页码
 * @param {number} pageSize - 每页数量
 * @returns {{ total, page, pageSize, totalPages }}
 */
function paginationMeta(total, page, pageSize) {
  return {
    total,
    page,
    pageSize,
    totalPages: Math.ceil(total / pageSize),
  };
}

/**
 * 生成随机绑定码（6位数字）
 * @returns {string} 6位数字字符串
 */
function generateBindCode() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

/**
 * 生成随机设备ID
 * @returns {string} UUID 格式的设备ID
 */
function generateDeviceId() {
  const { randomUUID } = require('crypto');
  return randomUUID();
}

/**
 * 将秒数格式化为 mm:ss
 * @param {number} seconds - 秒数
 * @returns {string} 格式化后的时间字符串
 */
function formatDuration(seconds) {
  if (!seconds && seconds !== 0) return '00:00';
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
}

/**
 * 判断情绪类型是否为消极情绪
 * @param {string} emotionType - 情绪类型
 * @returns {boolean}
 */
function isNegativeEmotion(emotionType) {
  const negativeTypes = ['anxious', 'sad', 'angry', 'confused'];
  return negativeTypes.includes(emotionType);
}

/**
 * 安全地解析 JSON 字符串
 * @param {string} str - JSON 字符串
 * @param {*} defaultValue - 解析失败时的默认值
 * @returns {*}
 */
function safeJsonParse(str, defaultValue = null) {
  try {
    return JSON.parse(str);
  } catch {
    return defaultValue;
  }
}

/**
 * 获取日期范围（用于统计查询）
 * @param {string} range - 范围类型：today/week/month
 * @returns {{ startDate: string, endDate: string }}
 */
function getDateRange(range) {
  const now = new Date();
  const endDate = now.toISOString().slice(0, 10);
  let startDate;

  switch (range) {
    case 'today':
      startDate = endDate;
      break;
    case 'week':
      startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10);
      break;
    case 'month':
      startDate = new Date(now.getFullYear(), now.getMonth(), 1).toISOString().slice(0, 10);
      break;
    default:
      startDate = endDate;
  }

  return { startDate, endDate };
}

module.exports = {
  parsePagination,
  paginationMeta,
  generateBindCode,
  generateDeviceId,
  formatDuration,
  isNegativeEmotion,
  safeJsonParse,
  getDateRange,
};
