/**
 * 认证相关 API
 * 包含登录、注册、登出、获取验证码等
 */
import request from './request'

/**
 * 手机号 + 密码登录
 * @param {Object} data - { phone, password }
 */
export function loginByPassword(data) {
  return request.post('/auth/login', data)
}

/**
 * 手机号 + 验证码登录
 * @param {Object} data - { phone, code }
 */
export function loginBySms(data) {
  return request.post('/auth/login/sms', data)
}

/**
 * 发送登录验证码
 * @param {string} phone - 手机号
 */
export function sendSmsCode(phone) {
  return request.post('/auth/sms-code', { phone })
}

/**
 * 辅导员注册
 * @param {Object} data - { name, phone, password, code, organization }
 */
export function register(data) {
  return request.post('/auth/register', data)
}

/**
 * 退出登录
 */
export function logout() {
  return request.post('/auth/logout')
}

/**
 * 刷新 Token
 */
export function refreshToken() {
  return request.post('/auth/refresh-token')
}

/**
 * 修改密码
 * @param {Object} data - { oldPassword, newPassword }
 */
export function changePassword(data) {
  return request.put('/auth/password', data)
}

/**
 * 获取当前用户信息
 */
export function getCurrentUser() {
  return request.get('/auth/me')
}
