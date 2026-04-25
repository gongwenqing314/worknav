/**
 * 统计分析 API
 * 包含任务统计、步骤耗时分析、情绪统计、报表导出
 */
import request from './request'

/**
 * 获取仪表盘概览数据
 */
export function getDashboardStats() {
  return request.get('/statistics/dashboard')
}

/**
 * 获取任务完成率趋势
 * @param {Object} params - { startDate, endDate, employeeId, granularity }
 */
export function getTaskCompletionTrend(params) {
  return request.get('/statistics/task-completion', { params })
}

/**
 * 获取步骤耗时分析（卡顿热点）
 * @param {Object} params - { taskId, startDate, endDate, topN }
 */
export function getStepDurationAnalysis(params) {
  return request.get('/statistics/step-duration', { params })
}

/**
 * 获取情绪统计
 * @param {Object} params - { startDate, endDate, employeeId, granularity }
 */
export function getEmotionStatistics(params) {
  return request.get('/statistics/emotion', { params })
}

/**
 * 获取员工工作统计
 * @param {Object} params - { startDate, endDate, employeeId }
 */
export function getEmployeeWorkStats(params) {
  return request.get('/statistics/employee-work', { params })
}

/**
 * 导出报表
 * @param {Object} data - { type, format, startDate, endDate, filters }
 */
export function exportReport(data) {
  return request.post('/statistics/export', data, {
    responseType: 'blob' // 文件下载
  })
}

/**
 * 获取报表下载链接
 * @param {string} reportId - 报表 ID
 */
export function getReportDownloadUrl(reportId) {
  return request.get(`/statistics/reports/${reportId}/download`)
}
