/**
 * 通知 API
 * 包含通知发送、通知列表、语音鼓励等
 */
import request from './request'

/**
 * 获取通知列表
 * @param {Object} params - { page, pageSize, type, read }
 */
export function getNotifications(params) {
  return request.get('/notifications', { params })
}

/**
 * 获取通知详情
 * @param {string} id - 通知 ID
 */
export function getNotificationDetail(id) {
  return request.get(`/notifications/${id}`)
}

/**
 * 发送通知
 * @param {Object} data - { title, content, type, targetEmployeeIds, targetType }
 */
export function sendNotification(data) {
  return request.post('/notifications', data)
}

/**
 * 发送语音鼓励通知
 * @param {Object} data - { employeeId, audioUrl, text }
 */
export function sendVoiceCheer(data) {
  return request.post('/notifications/voice-cheer', data)
}

/**
 * 标记通知为已读
 * @param {string} id - 通知 ID
 */
export function markNotificationRead(id) {
  return request.put(`/notifications/${id}/read`)
}

/**
 * 批量标记已读
 * @param {Object} data - { ids }
 */
export function batchMarkRead(data) {
  return request.put('/notifications/read-all', data)
}

/**
 * 删除通知
 * @param {string} id - 通知 ID
 */
export function deleteNotification(id) {
  return request.delete(`/notifications/${id}`)
}

/**
 * 获取未读通知数量
 */
export function getUnreadCount() {
  return request.get('/notifications/unread-count')
}
