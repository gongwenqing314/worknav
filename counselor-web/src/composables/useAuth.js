/**
 * 认证组合式函数
 * 封装登录/登出逻辑，供组件使用
 */
import { computed } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { hasPermission } from '@/utils/helpers'

export function useAuth() {
  const authStore = useAuthStore()

  /**
   * 是否已登录
   */
  const isLoggedIn = computed(() => authStore.isLoggedIn)

  /**
   * 当前用户角色
   */
  const userRole = computed(() => authStore.userRole)

  /**
   * 当前用户姓名
   */
  const userName = computed(() => authStore.userName)

  /**
   * 是否拥有指定权限
   * @param {string} requiredRole - 需要的角色
   */
  const checkPermission = (requiredRole) => {
    return hasPermission(authStore.userRole, requiredRole)
  }

  /**
   * 手机号密码登录
   */
  const login = async (credentials) => {
    return await authStore.loginByPasswordAction(credentials)
  }

  /**
   * 验证码登录
   */
  const loginBySms = async (credentials) => {
    return await authStore.loginBySmsAction(credentials)
  }

  /**
   * 退出登录
   */
  const logout = async () => {
    await authStore.logoutAction()
  }

  return {
    isLoggedIn,
    userRole,
    userName,
    checkPermission,
    login,
    loginBySms,
    logout
  }
}
