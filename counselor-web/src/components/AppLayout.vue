<template>
  <el-container class="app-layout">
    <el-aside :width="isCollapsed ? '64px' : '220px'" class="app-sidebar">
      <div class="sidebar-logo">
        <el-icon :size="28" color="#409EFF"><Location /></el-icon>
        <span v-show="!isCollapsed" class="logo-text">工作导航</span>
      </div>
      <el-scrollbar>
        <el-menu
          :default-active="activeMenu"
          :collapse="isCollapsed"
          :collapse-transition="false"
          background-color="#304156"
          text-color="#bfcbd9"
          active-text-color="#409EFF"
          @select="handleMenuSelect"
        >
          <el-menu-item index="/dashboard">
            <el-icon><Odometer /></el-icon>
            <template #title>首页仪表盘</template>
          </el-menu-item>
          <el-menu-item index="/employees">
            <el-icon><User /></el-icon>
            <template #title>员工管理</template>
          </el-menu-item>
          <el-menu-item index="/tasks">
            <el-icon><List /></el-icon>
            <template #title>任务管理</template>
          </el-menu-item>
          <el-menu-item v-if="checkPermission('counselor')" index="/templates">
            <el-icon><DocumentCopy /></el-icon>
            <template #title>任务模板</template>
          </el-menu-item>
          <el-menu-item v-if="checkPermission('counselor')" index="/schedule">
            <el-icon><Calendar /></el-icon>
            <template #title>排班管理</template>
          </el-menu-item>
          <el-menu-item v-if="checkPermission('counselor')" index="/communication">
            <el-icon><ChatDotRound /></el-icon>
            <template #title>沟通板配置</template>
          </el-menu-item>
          <el-menu-item index="/emotion">
            <el-icon><Sunny /></el-icon>
            <template #title>情绪监控</template>
          </el-menu-item>
          <el-menu-item v-if="checkPermission('counselor')" index="/remote-assist">
            <el-icon><VideoCamera /></el-icon>
            <template #title>远程协助</template>
          </el-menu-item>
          <el-menu-item index="/notifications">
            <el-icon><Bell /></el-icon>
            <template #title>通知中心</template>
            <el-badge v-if="unreadCount > 0" :value="unreadCount" class="nav-badge" />
          </el-menu-item>
          <el-menu-item v-if="checkPermission('counselor')" index="/statistics">
            <el-icon><DataAnalysis /></el-icon>
            <template #title>数据统计</template>
          </el-menu-item>
          <el-menu-item v-if="checkPermission('counselor')" index="/devices">
            <el-icon><Iphone /></el-icon>
            <template #title>设备管理</template>
          </el-menu-item>
          <el-menu-item index="/settings/profile">
            <el-icon><UserFilled /></el-icon>
            <template #title>个人设置</template>
          </el-menu-item>
          <el-menu-item v-if="checkPermission('admin')" index="/settings/system">
            <el-icon><Setting /></el-icon>
            <template #title>系统设置</template>
          </el-menu-item>
        </el-menu>
      </el-scrollbar>
    </el-aside>
    <el-container class="app-main-container">
      <el-header class="app-header" height="56px">
        <div class="header-left">
          <el-icon class="collapse-btn" @click="toggleCollapse" :size="20">
            <Fold v-if="!isCollapsed" />
            <Expand v-else />
          </el-icon>
          <el-breadcrumb separator="/">
            <el-breadcrumb-item v-for="item in breadcrumbs" :key="item.path">
              <router-link v-if="item.path" :to="item.path">{{ item.title }}</router-link>
              <span v-else>{{ item.title }}</span>
            </el-breadcrumb-item>
          </el-breadcrumb>
        </div>
        <div class="header-right">
          <el-badge :value="unreadCount" :hidden="unreadCount === 0" class="notification-badge">
            <el-icon :size="20" class="header-icon" @click="$router.push('/notifications')">
              <Bell />
            </el-icon>
          </el-badge>
          <el-dropdown trigger="click" @command="handleUserCommand">
            <div class="user-info">
              <el-avatar :size="32" icon="UserFilled" />
              <span class="user-name">{{ userName }}</span>
              <el-icon><ArrowDown /></el-icon>
            </div>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="profile">
                  <el-icon><UserFilled /></el-icon>个人设置
                </el-dropdown-item>
                <el-dropdown-item divided command="logout">
                  <el-icon><SwitchButton /></el-icon>退出登录
                </el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </el-header>
      <el-main class="app-main">
        <router-view :key="$route.fullPath" />
      </el-main>
    </el-container>
  </el-container>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useNotificationStore } from '@/stores/notification'
import { hasPermission } from '@/utils/helpers'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const notificationStore = useNotificationStore()

const isCollapsed = ref(false)
const userName = computed(() => authStore.userName || '辅导员')
const unreadCount = computed(() => notificationStore.unreadCount)
const activeMenu = computed(() => route.path)

const breadcrumbs = computed(() => {
  const matched = route.matched.filter(item => item.meta?.title)
  const crumbs = [{ title: '首页', path: '/dashboard' }]
  matched.forEach(item => {
    if (item.meta.title && item.path !== '/dashboard') {
      crumbs.push({ title: item.meta.title, path: item.redirect ? '' : item.path })
    }
  })
  return crumbs
})

const checkPermission = (role) => hasPermission(authStore.userRole, role)

const handleMenuSelect = (index) => {
  router.push(index)
}

const toggleCollapse = () => {
  isCollapsed.value = !isCollapsed.value
}

const handleUserCommand = (command) => {
  if (command === 'profile') {
    router.push('/settings/profile')
  } else if (command === 'logout') {
    authStore.logoutAction()
  }
}

onMounted(() => {
  notificationStore.fetchUnreadCount()
})
</script>

<style scoped>
.app-layout { height: 100vh; overflow: hidden; }
.app-sidebar {
  background-color: #304156;
  transition: width var(--transition-duration);
  overflow: hidden;
  display: flex;
  flex-direction: column;
}
.sidebar-logo {
  height: 56px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  flex-shrink: 0;
}
.logo-text { color: #fff; font-size: 18px; font-weight: 600; white-space: nowrap; }
.app-sidebar .el-menu { border-right: none; }
.nav-badge { position: absolute; right: 20px; }
.app-header {
  background: #fff;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 16px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.08);
  z-index: 10;
}
.header-left { display: flex; align-items: center; gap: 16px; }
.collapse-btn { cursor: pointer; color: #606266; transition: color 0.2s; }
.collapse-btn:hover { color: #409EFF; }
.header-right { display: flex; align-items: center; gap: 20px; }
.header-icon { cursor: pointer; color: #606266; transition: color 0.2s; }
.header-icon:hover { color: #409EFF; }
.notification-badge { line-height: 1; }
.user-info {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  padding: 4px 8px;
  border-radius: 4px;
  transition: background 0.2s;
}
.user-info:hover { background: #f5f7fa; }
.user-name {
  font-size: 14px;
  color: #303133;
  max-width: 100px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.app-main { background: var(--color-bg-page); overflow-y: auto; padding: 0; }
.app-main-container { flex-direction: column; overflow: hidden; }
@media screen and (max-width: 768px) {
  .app-sidebar { position: fixed; top: 0; left: 0; bottom: 0; z-index: 1000; }
  .user-name { display: none; }
}
</style>
