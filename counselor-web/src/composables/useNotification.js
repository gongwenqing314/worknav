/**
 * 通知组合式函数
 * 封装通知相关逻辑，支持 WebSocket 实时推送
 */
import { ref, onMounted, onUnmounted } from 'vue'
import { useNotificationStore } from '@/stores/notification'
import { io } from 'socket.io-client'

export function useNotification() {
  const notificationStore = useNotificationStore()
  const socket = ref(null)
  const connected = ref(false)

  /**
   * 初始化 WebSocket 连接
   * 监听实时通知推送
   */
  const initSocket = () => {
    const token = localStorage.getItem('token')
    if (!token) return

    const wsUrl = import.meta.env.VITE_WS_URL || window.location.origin
    socket.value = io(wsUrl, {
      auth: { token },
      transports: ['websocket', 'polling']
    })

    // 连接成功
    socket.value.on('connect', () => {
      connected.value = true
      console.log('WebSocket 已连接')
    })

    // 接收新通知
    socket.value.on('notification', (data) => {
      // 更新未读数量
      notificationStore.fetchUnreadCount()
      // 可在此处添加通知提醒逻辑（如 Element Plus 的 ElNotification）
    })

    // 接收情绪预警
    socket.value.on('emotion-alert', (data) => {
      notificationStore.fetchUnreadCount()
    })

    // 接收远程协助请求
    socket.value.on('assist-request', (data) => {
      notificationStore.fetchUnreadCount()
    })

    // 连接断开
    socket.value.on('disconnect', () => {
      connected.value = false
      console.log('WebSocket 已断开')
    })

    // 连接错误
    socket.value.on('connect_error', (error) => {
      connected.value = false
      console.error('WebSocket 连接错误:', error)
    })
  }

  /**
   * 断开 WebSocket 连接
   */
  const disconnectSocket = () => {
    if (socket.value) {
      socket.value.disconnect()
      socket.value = null
      connected.value = false
    }
  }

  /**
   * 获取未读数量
   */
  const fetchUnreadCount = async () => {
    await notificationStore.fetchUnreadCount()
  }

  /**
   * 获取通知列表
   */
  const fetchNotifications = async (params) => {
    return await notificationStore.fetchNotifications(params)
  }

  /**
   * 标记已读
   */
  const markRead = async (id) => {
    await notificationStore.markRead(id)
  }

  /**
   * 全部标记已读
   */
  const markAllRead = async () => {
    await notificationStore.markAllRead()
  }

  // 组件挂载时初始化
  onMounted(() => {
    initSocket()
    fetchUnreadCount()
  })

  // 组件卸载时断开连接
  onUnmounted(() => {
    disconnectSocket()
  })

  return {
    connected,
    unreadCount: notificationStore.unreadCount,
    notifications: notificationStore.notifications,
    hasUnread: notificationStore.hasUnread,
    fetchUnreadCount,
    fetchNotifications,
    markRead,
    markAllRead
  }
}
