/**
 * Axios 实例封装
 * 统一处理请求拦截、响应拦截、错误处理
 */
import axios from 'axios'
import { ElMessage, ElMessageBox } from 'element-plus'
import router from '@/router'

// 创建 Axios 实例
const request = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || '/api/v1',
  timeout: 30000, // 请求超时 30 秒
  headers: {
    'Content-Type': 'application/json'
  }
})

// 请求拦截器 - 自动携带 Token
request.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// 响应拦截器 - 统一处理错误码
request.interceptors.response.use(
  (response) => {
    const res = response.data
    // 如果后端返回的 code 不是 200 或 201，则视为业务错误
    if (res.code && res.code !== 200 && res.code !== 201) {
      ElMessage.error(res.message || '请求失败')
      // Token 过期或无效
      if (res.code === 401) {
        ElMessageBox.confirm('登录已过期，请重新登录', '提示', {
          confirmButtonText: '重新登录',
          cancelButtonText: '取消',
          type: 'warning'
        }).then(() => {
          localStorage.removeItem('token')
          localStorage.removeItem('userInfo')
          router.push('/login')
        })
      }
      return Promise.reject(new Error(res.message || '请求失败'))
    }
    return res
  },
  (error) => {
    // HTTP 状态码错误处理
    const status = error.response?.status
    const messages = {
      400: '请求参数错误',
      401: '未授权，请重新登录',
      403: '拒绝访问',
      404: '请求资源不存在',
      408: '请求超时',
      500: '服务器内部错误',
      502: '网关错误',
      503: '服务不可用',
      504: '网关超时'
    }
    const message = messages[status] || `连接出错(${status || '未知'})`
    ElMessage.error(message)

    // 401 跳转登录
    if (status === 401) {
      localStorage.removeItem('token')
      localStorage.removeItem('userInfo')
      router.push('/login')
    }

    return Promise.reject(error)
  }
)

export default request
