/**
 * 远程协助 API
 * 包含协助会话、图片标注、录音回传等
 */
import request from './request'

/**
 * 获取协助会话列表
 * @param {Object} params - { page, pageSize, status }
 */
export function getAssistRequests(params) {
  return request.get('/remote-assist/sessions', { params })
}

/**
 * 获取待接听的协助请求
 * @param {Object} params - { page, pageSize }
 */
export function getPendingRequests(params) {
  return request.get('/remote-assist/sessions/pending', { params })
}

/**
 * 获取协助会话详情（含消息历史）
 * @param {string} id - 会话 ID
 */
export function getAssistDetail(id) {
  return request.get(`/remote-assist/sessions/${id}`)
}

/**
 * 接受协助请求
 * @param {string} id - 会话 ID
 */
export function acceptAssistRequest(id) {
  return request.post(`/remote-assist/sessions/${id}/accept`)
}

/**
 * 拒绝协助请求
 * @param {string} id - 会话 ID
 * @param {Object} data - { reason }
 */
export function rejectAssistRequest(id, data) {
  return request.post(`/remote-assist/sessions/${id}/end`, data)
}

/**
 * 完成协助（结束会话）
 * @param {string} id - 会话 ID
 * @param {Object} data - { summary, rating }
 */
export function completeAssist(id, data) {
  return request.post(`/remote-assist/sessions/${id}/end`, data)
}

/**
 * 上传标注图片（画圈/箭头/文字标注）
 * @param {string} requestId - 会话 ID
 * @param {FormData} formData - 包含标注图片的表单数据
 */
export function uploadAnnotatedImage(requestId, formData) {
  return request.post(`/remote-assist/sessions/${requestId}/annotation`, formData, {
    headers: { 'Content-Type': 'multipart/form-data' }
  })
}

/**
 * 上传指导录音
 * @param {string} requestId - 会话 ID
 * @param {FormData} formData - 包含音频文件的表单数据
 */
export function uploadAssistAudio(requestId, formData) {
  return request.post(`/remote-assist/sessions/${requestId}/messages`, formData, {
    headers: { 'Content-Type': 'multipart/form-data' }
  })
}

/**
 * 获取协助历史记录
 * @param {Object} params - { page, pageSize, employeeId, startDate, endDate }
 */
export function getAssistHistory(params) {
  return request.get('/remote-assist/sessions', { params })
}
