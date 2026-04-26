/**
 * 通知状态管理（Pinia）
 * 管理未读通知数量、通知列表等
 */
import { defineStore } from 'pinia'
import {
  getNotifications,
  getUnreadCount,
  markNotificationRead,
  batchMarkRead,
  deleteNotification as deleteNotificationApi
} from '@/api/notification'

export const useNotificationStore = defineStore('notification', {
  state: () => ({
    // 通知列表
    notifications: [],
    // 通知总数
    total: 0,
    // 未读数量
    unreadCount: 0,
    // 列表加载状态
    listLoading: false,
    // 查询参数
    queryParams: {
      page: 1,
      pageSize: 20,
      type: '',
      read: ''
    }
  }),

  getters: {
    /**
     * 是否有未读通知
     */
    hasUnread: (state) => state.unreadCount > 0
  },

  actions: {
    /**
     * 获取通知列表
     */
    async fetchNotifications(params = {}) {
      this.listLoading = true
      try {
        const queryParams = { ...this.queryParams, ...params }
        // 前端 read: 'unread'/'read' → 后端 isRead: 0/1
        if (queryParams.read === 'unread') {
          queryParams.isRead = 0
          delete queryParams.read
        } else if (queryParams.read === 'read') {
          queryParams.isRead = 1
          delete queryParams.read
        } else {
          delete queryParams.read
        }
        const res = await getNotifications(queryParams)
        this.notifications = res.data?.list || res.data || []
        this.total = res.data?.total || 0
        return res
      } finally {
        this.listLoading = false
      }
    },

    /**
     * 获取未读数量
     */
    async fetchUnreadCount() {
      try {
        const res = await getUnreadCount()
        this.unreadCount = res.data?.count || 0
        return this.unreadCount
      } catch (error) {
        console.error('获取未读数量失败:', error)
      }
    },

    /**
     * 标记单条通知为已读
     */
    async markRead(id) {
      await markNotificationRead(id)
      // 更新本地状态
      const notification = this.notifications.find(n => n.id === id)
      if (notification) {
        notification.read = true
      }
      if (this.unreadCount > 0) {
        this.unreadCount--
      }
    },

    /**
     * 批量标记已读
     */
    async markAllRead() {
      const unreadIds = this.notifications
        .filter(n => !n.read)
        .map(n => n.id)
      if (unreadIds.length === 0) return
      await batchMarkRead({ ids: unreadIds })
      // 更新本地状态
      this.notifications.forEach(n => { n.read = true })
      this.unreadCount = 0
    },

    /**
     * 删除通知
     */
    async deleteNotification(id) {
      await deleteNotificationApi(id)
      const index = this.notifications.findIndex(n => n.id === id)
      if (index > -1) {
        this.notifications.splice(index, 1)
        this.total--
      }
    },

    /**
     * 设置查询参数
     */
    setQueryParams(params) {
      this.queryParams = { ...this.queryParams, ...params }
    }
  }
})
