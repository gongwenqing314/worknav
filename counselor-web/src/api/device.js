/**
 * 设备管理 API
 * 包含设备列表、绑定码生成、远程解绑等
 */
import request from './request'

/**
 * 获取设备列表
 * @param {Object} params - { page, pageSize, employeeId, status }
 */
export function getDeviceList(params) {
  return request.get('/devices', { params })
}

/**
 * 获取设备详情
 * @param {string} id - 设备 ID
 */
export function getDeviceDetail(id) {
  return request.get(`/devices/${id}`)
}

/**
 * 生成设备绑定码
 * @param {Object} data - { employeeId, expiresIn }
 */
export function generateBindCode(data) {
  return request.post('/devices/bind-code', data)
}

/**
 * 解绑设备
 * @param {string} id - 设备 ID
 */
export function unbindDevice(id) {
  return request.delete(`/devices/${id}`)
}

/**
 * 远程锁定设备
 * @param {string} id - 设备 ID
 */
export function lockDevice(id) {
  return request.post(`/devices/${id}/lock`)
}

/**
 * 远程解锁设备
 * @param {string} id - 设备 ID
 */
export function unlockDevice(id) {
  return request.post(`/devices/${id}/unlock`)
}

/**
 * 获取设备在线状态
 * @param {string} id - 设备 ID
 */
export function getDeviceOnlineStatus(id) {
  return request.get(`/devices/${id}/online-status`)
}

/**
 * 向设备推送配置
 * @param {string} id - 设备 ID
 * @param {Object} data - 配置数据
 */
export function pushDeviceConfig(id, data) {
  return request.post(`/devices/${id}/push-config`, data)
}
