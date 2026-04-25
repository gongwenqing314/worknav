/**
 * 用户管理 API
 * 包含员工（心智障碍人士）管理、家长绑定等
 */
import request from './request'

/**
 * 获取员工列表
 * @param {Object} params - { page, pageSize, keyword, status, groupId }
 */
export function getEmployeeList(params) {
  return request.get('/users/employees/list', { params })
}

/**
 * 获取员工详情
 * @param {string} id - 员工 ID
 */
export function getEmployeeDetail(id) {
  return request.get(`/users/employees/${id}/profile`)
}

/**
 * 创建员工档案
 * @param {Object} data - 员工信息
 */
export function createEmployee(data) {
  return request.post('/users/employees', data)
}

/**
 * 更新员工档案
 * @param {string} id - 员工 ID
 * @param {Object} data - 更新数据
 */
export function updateEmployee(id, data) {
  return request.put(`/users/employees/${id}`, data)
}

/**
 * 删除员工
 * @param {string} id - 员工 ID
 */
export function deleteEmployee(id) {
  return request.delete(`/users/employees/${id}`)
}

/**
 * 获取家长绑定列表
 * @param {string} employeeId - 员工 ID
 */
export function getParentBindings(employeeId) {
  return request.get(`/users/employees/${employeeId}/parents`)
}

/**
 * 生成家长绑定邀请链接
 * @param {string} employeeId - 员工 ID
 * @param {Object} data - { relation, expiresIn }
 */
export function generateParentInvite(employeeId, data) {
  return request.post(`/users/employees/${employeeId}/parents/invite`, data)
}

/**
 * 解绑家长
 * @param {string} employeeId - 员工 ID
 * @param {string} parentId - 家长 ID
 */
export function unbindParent(employeeId, parentId) {
  return request.delete(`/users/employees/${employeeId}/parents/${parentId}`)
}

/**
 * 获取员工分组列表
 */
export function getGroups() {
  return request.get('/users/groups')
}

/**
 * 创建分组
 * @param {Object} data - { name, description }
 */
export function createGroup(data) {
  return request.post('/groups', data)
}

/**
 * 将员工分配到分组
 * @param {string} groupId - 分组 ID
 * @param {Object} data - { employeeIds }
 */
export function assignEmployeesToGroup(groupId, data) {
  return request.post(`/groups/${groupId}/employees`, data)
}
