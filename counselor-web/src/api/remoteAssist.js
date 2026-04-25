/**
 * 远程协助 API
 * 包含协助请求、图片标注、录音回传等
 */
import request from './request'

/**
 * 获取待处理的协助请求列表
 * @param {Object} params - { page, pageSize, status }
 */
export function getAssistRequests(params) {
  return request.get('/remote-assist/requests', { params })
}

/**
 * 获取协助请求详情
 * @param {string} id - 请求 ID
 */
export function getAssistDetail(id) {
  return request.get(`/remote-assist/requests/${id}`)
}

/**
 * 接受协助请求
 * @param {string} id - 请求 ID
 */
export function acceptAssistRequest(id) {
  return request.post(`/remote-assist/requests/${id}/accept`)
}

/**
 * 拒绝协助请求
 * @param {string} id - 请求 ID
 * @param {Object} data - { reason }
 */
export function rejectAssistRequest(id, data) {
  return request.post(`/remote-assist/requests/${id}/reject`, data)
}

/**
 * 完成协助
 * @param {string} id - 请求 ID
 * @param {Object} data - { summary }
 */
export function completeAssist(id, data) {
  return request.post(`/remote-assist/requests/${id}/complete`, data)
}

/**
 * 上传标注图片（画圈/箭头/文字标注）
 * @param {string} requestId - 请求 ID
 * @param {FormData} formData - 包含标注图片的表单数据
 */
export function uploadAnnotatedImage(requestId, formData) {
  return request.post(`/remote-assist/requests/${requestId}/annotate`, formData, {
    headers: { 'Content-Type': 'multipart/form-data' }
  })
}

/**
 * 上传指导录音
 * @param {string} requestId - 请求 ID
 * @param {FormData} formData - 包含音频文件的表单数据
 */
export function uploadAssistAudio(requestId, formData) {
  return request.post(`/remote-assist/requests/${requestId}/audio`, formData, {
    headers: { 'Content-Type': 'multipart/form-data' }
  })
}

/**
 * 获取协助历史记录
 * @param {Object} params - { page, pageSize, employeeId, startDate, endDate }
 */
export function getAssistHistory(params) {
  return request.get('/remote-assist/history', { params })
}
