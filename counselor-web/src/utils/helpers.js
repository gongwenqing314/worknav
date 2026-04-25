/**
 * 辅助函数
 * 提供通用的工具方法
 */
import dayjs from 'dayjs'
import { DATE_FORMATS } from './constants'

/**
 * 格式化日期
 * @param {string|Date} date - 日期
 * @param {string} format - 格式字符串
 * @returns {string}
 */
export function formatDate(date, format = DATE_FORMATS.DATE) {
  if (!date) return '-'
  return dayjs(date).format(format)
}

/**
 * 格式化文件大小
 * @param {number} bytes - 字节数
 * @returns {string}
 */
export function formatFileSize(bytes) {
  if (!bytes) return '0 B'
  const units = ['B', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(1024))
  return (bytes / Math.pow(1024, i)).toFixed(2) + ' ' + units[i]
}

/**
 * 格式化时长（秒 -> 分:秒）
 * @param {number} seconds - 秒数
 * @returns {string}
 */
export function formatDuration(seconds) {
  if (!seconds && seconds !== 0) return '-'
  const m = Math.floor(seconds / 60)
  const s = Math.floor(seconds % 60)
  return `${m}分${s}秒`
}

/**
 * 计算百分比
 * @param {number} current - 当前值
 * @param {number} total - 总值
 * @returns {number}
 */
export function calcPercent(current, total) {
  if (!total) return 0
  return Math.round((current / total) * 100)
}

/**
 * 防抖函数
 * @param {Function} fn - 要防抖的函数
 * @param {number} delay - 延迟毫秒数
 * @returns {Function}
 */
export function debounce(fn, delay = 300) {
  let timer = null
  return function (...args) {
    if (timer) clearTimeout(timer)
    timer = setTimeout(() => {
      fn.apply(this, args)
    }, delay)
  }
}

/**
 * 节流函数
 * @param {Function} fn - 要节流的函数
 * @param {number} delay - 间隔毫秒数
 * @returns {Function}
 */
export function throttle(fn, delay = 300) {
  let lastTime = 0
  return function (...args) {
    const now = Date.now()
    if (now - lastTime >= delay) {
      lastTime = now
      fn.apply(this, args)
    }
  }
}

/**
 * 深拷贝对象
 * @param {*} obj - 要拷贝的对象
 * @returns {*}
 */
export function deepClone(obj) {
  if (obj === null || typeof obj !== 'object') return obj
  return JSON.parse(JSON.stringify(obj))
}

/**
 * 生成唯一 ID（简易版）
 * @returns {string}
 */
export function generateId() {
  return Date.now().toString(36) + Math.random().toString(36).substring(2, 8)
}

/**
 * 下载文件
 * @param {Blob} blob - 文件 Blob
 * @param {string} filename - 文件名
 */
export function downloadFile(blob, filename) {
  const url = window.URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = filename
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
  window.URL.revokeObjectURL(url)
}

/**
 * 手机号脱敏
 * @param {string} phone - 手机号
 * @returns {string}
 */
export function maskPhone(phone) {
  if (!phone || phone.length !== 11) return phone
  return phone.replace(/(\d{3})\d{4}(\d{4})/, '$1****$2')
}

/**
 * 获取相对时间描述
 * @param {string|Date} date - 日期
 * @returns {string}
 */
export function getRelativeTime(date) {
  if (!date) return '-'
  const now = dayjs()
  const target = dayjs(date)
  const diffMinutes = now.diff(target, 'minute')

  if (diffMinutes < 1) return '刚刚'
  if (diffMinutes < 60) return `${diffMinutes}分钟前`
  const diffHours = now.diff(target, 'hour')
  if (diffHours < 24) return `${diffHours}小时前`
  const diffDays = now.diff(target, 'day')
  if (diffDays < 30) return `${diffDays}天前`
  return formatDate(date)
}

/**
 * 检查是否有权限
 * @param {string} userRole - 当前用户角色
 * @param {string} requiredRole - 需要的角色
 * @returns {boolean}
 */
export function hasPermission(userRole, requiredRole) {
  // 权限等级：admin > counselor > assistant
  const roleLevels = { admin: 3, counselor: 2, assistant: 1 }
  return (roleLevels[userRole] || 0) >= (roleLevels[requiredRole] || 0)
}
