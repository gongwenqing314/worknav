/**
 * 排班管理 API
 * 包含排班日历、批量任务分配等
 */
import request from './request'

/**
 * 获取排班日历数据
 * @param {Object} params - { year, month, employeeId }
 */
export function getScheduleCalendar(params) {
  return request.get('/schedules', { params })
}

/**
 * 创建排班
 * @param {Object} data - { employeeId, date, taskId, startTime, endTime }
 */
export function createSchedule(data) {
  return request.post('/schedules', data)
}

/**
 * 批量创建排班
 * @param {Object} data - { items: [{ employeeId, date, taskId, startTime, endTime }] }
 */
export function batchCreateSchedules(data) {
  return request.post('/schedules/batch', data)
}

/**
 * 更新排班
 * @param {string} id - 排班 ID
 * @param {Object} data - 更新数据
 */
export function updateSchedule(id, data) {
  return request.put(`/schedules/${id}`, data)
}

/**
 * 删除排班
 * @param {string} id - 排班 ID
 */
export function deleteSchedule(id) {
  return request.delete(`/schedules/${id}`)
}

/**
 * 获取某日排班详情
 * @param {string} date - 日期 YYYY-MM-DD
 */
export function getScheduleByDate(date) {
  return request.get(`/schedules/date/${date}`)
}

/**
 * 获取排班统计
 * @param {Object} params - { startDate, endDate, employeeId }
 */
export function getScheduleStats(params) {
  return request.get('/schedules/stats', { params })
}
