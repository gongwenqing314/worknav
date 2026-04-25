/**
 * 认证状态管理（Pinia）
 * 管理用户登录状态、Token、用户信息
 */
import { defineStore } from 'pinia'
import { loginByPassword, loginBySms, logout as logoutApi, getCurrentUser } from '@/api/auth'
import router from '@/router'

export const useAuthStore = defineStore('auth', {
  state: () => ({
    // 访问令牌
    token: localStorage.getItem('token') || '',
    // 用户信息
    userInfo: JSON.parse(localStorage.getItem('userInfo') || 'null'),
    // 登录加载状态
    loading: false
  }),

  getters: {
    /**
     * 是否已登录
     */
    isLoggedIn: (state) => !!state.token,

    /**
     * 当前用户角色
     */
    userRole: (state) => state.userInfo?.role || '',

    /**
     * 当前用户姓名
     */
    userName: (state) => state.userInfo?.name || '',

    /**
     * 是否为主管理辅导员（拥有全部权限）
     */
    isMainCounselor: (state) => state.userInfo?.role === 'counselor' || state.userInfo?.role === 'admin',

    /**
     * 是否为管理员
     */
    isAdmin: (state) => state.userInfo?.role === 'admin'
  },

  actions: {
    /**
     * 手机号 + 密码登录
     */
    async loginByPasswordAction(credentials) {
      this.loading = true
      try {
        const res = await loginByPassword(credentials)
        this.setAuthData(res.data)
        return res
      } finally {
        this.loading = false
      }
    },

    /**
     * 手机号 + 验证码登录
     */
    async loginBySmsAction(credentials) {
      this.loading = true
      try {
        const res = await loginBySms(credentials)
        this.setAuthData(res.data)
        return res
      } finally {
        this.loading = false
      }
    },

    /**
     * 设置认证数据（Token + 用户信息）
     */
    setAuthData(data) {
      this.token = data.token || data.accessToken
      this.userInfo = data.user || data.userInfo
      localStorage.setItem('token', this.token)
      localStorage.setItem('userInfo', JSON.stringify(this.userInfo))
    },

    /**
     * 获取当前用户信息
     */
    async fetchUserInfo() {
      try {
        const res = await getCurrentUser()
        this.userInfo = res.data
        localStorage.setItem('userInfo', JSON.stringify(res.data))
        return res.data
      } catch (error) {
        console.error('获取用户信息失败:', error)
        throw error
      }
    },

    /**
     * 退出登录
     */
    async logoutAction() {
      try {
        await logoutApi()
      } catch (error) {
        // 即使退出 API 失败也要清除本地状态
        console.warn('退出登录 API 调用失败:', error)
      } finally {
        this.clearAuth()
        router.push('/login')
      }
    },

    /**
     * 清除认证数据
     */
    clearAuth() {
      this.token = ''
      this.userInfo = null
      localStorage.removeItem('token')
      localStorage.removeItem('userInfo')
    }
  }
})
