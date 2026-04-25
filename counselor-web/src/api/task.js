/**
 * 任务管理 API
 * 包含任务的增删改查、步骤管理、任务执行记录等
 */
import request from './request'

/**
 * 获取任务列表
 * @param {Object} params - { page, pageSize, status, employeeId, keyword, date }
 */
export function getTaskList(params) {
  return request.get('/tasks/instances', { params })
}

/**
 * 获取任务详情
 * @param {string} id - 任务 ID
 */
export function getTaskDetail(id) {
  return request.get(`/tasks/instances/${id}`)
}

/**
 * 创建任务
 * @param {Object} data - 任务数据（含 steps 步骤列表）
 */
export function createTask(data) {
  return request.post('/tasks/instances', data)
}

/**
 * 更新任务
 * @param {string} id - 任务 ID
 * @param {Object} data - 更新数据
 */
export function updateTask(id, data) {
  return request.put(`/tasks/instances/${id}`, data)
}

/**
 * 删除任务
 * @param {string} id - 任务 ID
 */
export function deleteTask(id) {
  return request.delete(`/tasks/instances/${id}`)
}

/**
 * 分配任务给员工
 * @param {string} taskId - 任务 ID
 * @param {Object} data - { employeeIds, scheduledDate }
 */
export function assignTask(taskId, data) {
  return request.post(`/tasks/instances/assign`, data)
}

/**
 * 获取任务执行记录
 * @param {string} taskId - 任务 ID
 * @param {Object} params - { employeeId, date }
 */
export function getTaskExecutions(taskId, params) {
  return request.get(`/tasks/${taskId}/executions`, { params })
}

/**
 * 获取任务实时执行状态
 * @param {string} taskId - 任务 ID
 */
export function getTaskLiveStatus(taskId) {
  return request.get(`/tasks/${taskId}/live`)
}

/**
 * 获取任务模板列表
 * @param {Object} params - { page, pageSize, category }
 */
export function getTemplateList(params) {
  return request.get('/tasks/templates', { params })
}

/**
 * 获取模板详情
 * @param {string} id - 模板 ID
 */
export function getTemplateDetail(id) {
  return request.get(`/tasks/templates/${id}`)
}

/**
 * 创建任务模板
 * @param {Object} data - 模板数据（含 steps ）
 */
export function createTemplate(data) {
  return request.post('/tasks/templates', data)
}

/**
 * 更新任务模板
 * @param {string} id - 模板 ID
 * @param {Object} data - 更新数据
 */
export function updateTemplate(id, data) {
  return request.put(`/tasks/templates/${id}`, data)
}

/**
 * 删除任务模板
 * @param {string} id - 模板 ID
 */
export function deleteTemplate(id) {
  return request.delete(`/tasks/templates/${id}`)
}

/**
 * 从模板创建任务
 * @param {string} templateId - 模板 ID
 * @param {Object} data - { employeeIds, scheduledDate }
 */
export function createTaskFromTemplate(templateId, data) {
  return request.post(`/tasks/templates/${templateId}/create-task`, data)
}
