/**
 * 情绪相关 API
 * 包含情绪记录、情绪趋势、预警规则等
 */
import request from './request'

/**
 * 获取情绪记录列表
 * @param {Object} params - { page, pageSize, employeeId, emotion, startDate, endDate }
 */
export function getEmotionRecords(params) {
  return request.get('/emotions', { params })
}

/**
 * 获取员工情绪趋势
 * @param {string} employeeId - 员工 ID
 * @param {Object} params - { startDate, endDate, granularity }
 */
export function getEmotionTrend(employeeId, params) {
  return request.get(`/emotions/${employeeId}/trend`, { params })
}

/**
 * 获取当前所有员工的实时情绪状态
 */
export function getEmotionOverview() {
  return request.get('/emotions/overview')
}

/**
 * 获取预警列表
 * @param {Object} params - { page, pageSize, level, handled }
 */
export function getEmotionAlerts(params) {
  return request.get('/emotions/alerts', { params })
}

/**
 * 处理预警
 * @param {string} alertId - 预警 ID
 * @param {Object} data - { action, note }
 */
export function handleAlert(alertId, data) {
  return request.post(`/emotions/alerts/${alertId}/handle`, data)
}

/**
 * 获取预警规则列表
 */
export function getAlertRules() {
  return request.get('/emotions/alert-rules')
}

/**
 * 创建预警规则
 * @param {Object} data - { name, emotion, threshold, duration, notifyCounselors }
 */
export function createAlertRule(data) {
  return request.post('/emotions/alert-rules', data)
}

/**
 * 更新预警规则
 * @param {string} id - 规则 ID
 * @param {Object} data - 更新数据
 */
export function updateAlertRule(id, data) {
  return request.put(`/emotions/alert-rules/${id}`, data)
}

/**
 * 删除预警规则
 * @param {string} id - 规则 ID
 */
export function deleteAlertRule(id) {
  return request.delete(`/emotions/alert-rules/${id}`)
}
