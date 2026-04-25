/**
 * 沟通板 API
 * 包含沟通板分类、常用语管理（文字+语音）
 */
import request from './request'

/**
 * 获取沟通板分类列表
 * @param {Object} params - { page, pageSize }
 */
export function getCommCategories(params) {
  return request.get('/communication/categories', { params })
}

/**
 * 创建沟通板分类
 * @param {Object} data - { name, icon, sortOrder }
 */
export function createCommCategory(data) {
  return request.post('/communication/categories', data)
}

/**
 * 更新沟通板分类
 * @param {string} id - 分类 ID
 * @param {Object} data - 更新数据
 */
export function updateCommCategory(id, data) {
  return request.put(`/communication/categories/${id}`, data)
}

/**
 * 删除沟通板分类
 * @param {string} id - 分类 ID
 */
export function deleteCommCategory(id) {
  return request.delete(`/communication/categories/${id}`)
}

/**
 * 获取分类下的常用语列表
 * @param {string} categoryId - 分类 ID
 * @param {Object} params - { page, pageSize }
 */
export function getPhrases(categoryId, params) {
  return request.get(`/communication/categories/${categoryId}/phrases`, { params })
}

/**
 * 创建常用语
 * @param {string} categoryId - 分类 ID
 * @param {Object} data - { text, audioUrl, imageUrl, sortOrder }
 */
export function createPhrase(categoryId, data) {
  return request.post(`/communication/categories/${categoryId}/phrases`, data)
}

/**
 * 更新常用语
 * @param {string} categoryId - 分类 ID
 * @param {string} phraseId - 常用语 ID
 * @param {Object} data - 更新数据
 */
export function updatePhrase(categoryId, phraseId, data) {
  return request.put(`/communication/categories/${categoryId}/phrases/${phraseId}`, data)
}

/**
 * 删除常用语
 * @param {string} categoryId - 分类 ID
 * @param {string} phraseId - 常用语 ID
 */
export function deletePhrase(categoryId, phraseId) {
  return request.delete(`/communication/categories/${categoryId}/phrases/${phraseId}`)
}

/**
 * 上传沟通板资源（图片/音频）
 * @param {FormData} formData - 文件表单数据
 */
export function uploadCommResource(formData) {
  return request.post('/communication/upload', formData, {
    headers: { 'Content-Type': 'multipart/form-data' }
  })
}

/**
 * 获取沟通板预览数据（用于员工端展示）
 * @param {string} employeeId - 员工 ID
 */
export function getCommBoardPreview(employeeId) {
  return request.get(`/communication/preview/${employeeId}`)
}
