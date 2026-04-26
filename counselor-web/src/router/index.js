/**
 * Vue Router 配置
 * 包含路由定义和权限守卫
 */
import { createRouter, createWebHistory } from 'vue-router'

// 路由配置
const routes = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/auth/LoginView.vue'),
    meta: { title: '登录', requiresAuth: false }
  },
  {
    path: '/register',
    name: 'Register',
    component: () => import('@/views/auth/RegisterView.vue'),
    meta: { title: '注册', requiresAuth: false }
  },
  {
    path: '/',
    component: () => import('@/layouts/DefaultLayout.vue'),
    redirect: '/dashboard',
    meta: { requiresAuth: true },
    children: [
      {
        path: 'dashboard',
        name: 'Dashboard',
        component: () => import('@/views/dashboard/DashboardView.vue'),
        meta: { title: '首页仪表盘', icon: 'Odometer' }
      },
      // ===== 员工管理 =====
      {
        path: 'employees',
        name: 'EmployeeList',
        component: () => import('@/views/employees/EmployeeList.vue'),
        meta: { title: '员工管理', icon: 'User', requiredRole: 'assistant' }
      },
      {
        path: 'employees/:id',
        name: 'EmployeeDetail',
        component: () => import('@/views/employees/EmployeeDetail.vue'),
        meta: { title: '员工详情', hidden: true }
      },
      {
        path: 'employees/:id/parent-bind',
        name: 'ParentBind',
        component: () => import('@/views/employees/ParentBind.vue'),
        meta: { title: '家长绑定', hidden: true, requiredRole: 'counselor' }
      },
      // ===== 任务管理 =====
      {
        path: 'tasks',
        name: 'TaskList',
        component: () => import('@/views/tasks/TaskList.vue'),
        meta: { title: '任务管理', icon: 'List', requiredRole: 'assistant' }
      },
      {
        path: 'tasks/create',
        name: 'TaskCreate',
        component: () => import('@/views/tasks/TaskCreate.vue'),
        meta: { title: '创建任务', hidden: true, requiredRole: 'assistant' }
      },
      {
        path: 'tasks/:id/edit',
        name: 'TaskEdit',
        component: () => import('@/views/tasks/TaskCreate.vue'),
        meta: { title: '编辑任务', hidden: true, requiredRole: 'assistant' }
      },
      {
        path: 'tasks/:id/monitor',
        name: 'TaskMonitor',
        component: () => import('@/views/tasks/TaskMonitor.vue'),
        meta: { title: '任务监控', hidden: true }
      },
      // ===== 任务模板 =====
      {
        path: 'templates',
        name: 'TemplateList',
        component: () => import('@/views/templates/TemplateList.vue'),
        meta: { title: '任务模板', icon: 'DocumentCopy', requiredRole: 'counselor' }
      },
      // ===== 排班管理 =====
      {
        path: 'schedule',
        name: 'ScheduleManage',
        component: () => import('@/views/schedule/ScheduleManage.vue'),
        meta: { title: '排班管理', icon: 'Calendar', requiredRole: 'counselor' }
      },
      // ===== 沟通板 =====
      {
        path: 'communication',
        name: 'CommBoard',
        component: () => import('@/views/communication/CommBoard.vue'),
        meta: { title: '沟通板配置', icon: 'ChatDotRound', requiredRole: 'counselor' }
      },
      {
        path: 'communication/:categoryId/phrases',
        name: 'PhraseEditor',
        component: () => import('@/views/communication/PhraseEditor.vue'),
        meta: { title: '常用语编辑', hidden: true, requiredRole: 'counselor' }
      },
      // ===== 情绪监控 =====
      {
        path: 'emotion',
        name: 'EmotionMonitor',
        component: () => import('@/views/emotion/EmotionMonitor.vue'),
        meta: { title: '情绪监控', icon: 'Sunny', requiredRole: 'counselor' }
      },
      {
        path: 'emotion/alert-rules',
        name: 'AlertRules',
        component: () => import('@/views/emotion/AlertRules.vue'),
        meta: { title: '预警规则', hidden: true, requiredRole: 'counselor' }
      },
      // ===== 远程协助 =====
      {
        path: 'remote-assist',
        name: 'AssistCenter',
        component: () => import('@/views/remoteAssist/AssistCenter.vue'),
        meta: { title: '远程协助', icon: 'VideoCamera', requiredRole: 'counselor' }
      },
      // ===== 通知中心 =====
      {
        path: 'notifications',
        name: 'NotificationCenter',
        component: () => import('@/views/notifications/NotificationCenter.vue'),
        meta: { title: '通知中心', icon: 'Bell', requiredRole: 'assistant' }
      },
      // ===== 数据统计 =====
      {
        path: 'statistics',
        name: 'TaskStatistics',
        component: () => import('@/views/statistics/TaskStatistics.vue'),
        meta: { title: '任务统计', icon: 'DataAnalysis', requiredRole: 'counselor' }
      },
      {
        path: 'statistics/step-duration',
        name: 'StepDuration',
        component: () => import('@/views/statistics/StepDuration.vue'),
        meta: { title: '步骤耗时分析', hidden: true, requiredRole: 'counselor' }
      },
      {
        path: 'statistics/emotion',
        name: 'EmotionStatistics',
        component: () => import('@/views/statistics/EmotionStatistics.vue'),
        meta: { title: '情绪统计', hidden: true, requiredRole: 'counselor' }
      },
      {
        path: 'statistics/report-export',
        name: 'ReportExport',
        component: () => import('@/views/statistics/ReportExport.vue'),
        meta: { title: '报表导出', hidden: true, requiredRole: 'counselor' }
      },
      // ===== 设置 =====
      {
        path: 'settings/system',
        name: 'SystemSettings',
        component: () => import('@/views/settings/SystemSettings.vue'),
        meta: { title: '系统设置', icon: 'Setting', requiredRole: 'admin' }
      },
      {
        path: 'settings/profile',
        name: 'ProfileSettings',
        component: () => import('@/views/settings/ProfileSettings.vue'),
        meta: { title: '个人设置', icon: 'UserFilled', requiredRole: 'assistant' }
      },
      // ===== 设备管理 =====
      {
        path: 'devices',
        name: 'DeviceManage',
        component: () => import('@/views/devices/DeviceManage.vue'),
        meta: { title: '设备管理', icon: 'Iphone', requiredRole: 'counselor' }
      }
    ]
  },
  // 404 页面
  {
    path: '/:pathMatch(.*)*',
    redirect: '/dashboard'
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes,
  // 路由切换时滚动到顶部
  scrollBehavior() {
    return { top: 0 }
  }
})

// ===== 全局前置守卫 =====
router.afterEach((to, from) => {
  // 导航完成钩子
})

router.beforeEach((to, from, next) => {
  // 设置页面标题
  document.title = to.meta.title
    ? `${to.meta.title} - 工作导航`
    : '工作导航 - 辅导员管理后台'

  const token = localStorage.getItem('token')

  // 需要认证但未登录 -> 跳转登录
  if (to.meta.requiresAuth !== false && !token) {
    next({ path: '/login', query: { redirect: to.fullPath } })
    return
  }

  // 已登录访问登录/注册页 -> 跳转首页
  if (token && (to.path === '/login' || to.path === '/register')) {
    next({ path: '/' })
    return
  }

  // 按钮级权限检查（角色不足则跳转 404）
  if (to.meta.requiredRole && token) {
    const userInfo = JSON.parse(localStorage.getItem('userInfo') || '{}')
    const roleLevels = { admin: 3, counselor: 2, assistant: 1 }
    const userLevel = roleLevels[userInfo.role] || 0
    const requiredLevel = roleLevels[to.meta.requiredRole] || 0
    if (userLevel < requiredLevel) {
      next({ path: '/dashboard' })
      return
    }
  }

  next()
})

export default router
