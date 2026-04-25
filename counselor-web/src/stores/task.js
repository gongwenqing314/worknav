/**
 * 任务状态管理（Pinia）
 * 管理任务列表、当前编辑任务、任务执行状态等
 */
import { defineStore } from 'pinia'
import {
  getTaskList,
  getTaskDetail,
  createTask as createTaskApi,
  updateTask as updateTaskApi,
  deleteTask as deleteTaskApi,
  getTaskLiveStatus
} from '@/api/task'

export const useTaskStore = defineStore('task', {
  state: () => ({
    // 任务列表
    taskList: [],
    // 列表总数
    total: 0,
    // 列表加载状态
    listLoading: false,
    // 当前编辑的任务
    currentTask: null,
    // 任务详情加载状态
    detailLoading: false,
    // 任务实时执行状态（用于监控页面）
    liveStatusMap: {},
    // 查询参数
    queryParams: {
      page: 1,
      pageSize: 20,
      status: '',
      employeeId: '',
      keyword: '',
      date: ''
    }
  }),

  getters: {
    /**
     * 按状态统计任务数量
     */
    taskStats: (state) => {
      const stats = { draft: 0, pending: 0, in_progress: 0, completed: 0, cancelled: 0 }
      state.taskList.forEach(task => {
        if (stats[task.status] !== undefined) {
          stats[task.status]++
        }
      })
      return stats
    }
  },

  actions: {
    /**
     * 获取任务列表
     */
    async fetchTaskList(params = {}) {
      this.listLoading = true
      try {
        const queryParams = { ...this.queryParams, ...params }
        const res = await getTaskList(queryParams)
        this.taskList = res.data?.list || res.data?.data?.list || []
        this.total = res.data?.total || res.data?.pagination?.total || 0
        return res
      } finally {
        this.listLoading = false
      }
    },

    /**
     * 获取任务详情
     */
    async fetchTaskDetail(id) {
      this.detailLoading = true
      try {
        const res = await getTaskDetail(id)
        this.currentTask = res.data
        return res.data
      } finally {
        this.detailLoading = false
      }
    },

    /**
     * 创建任务
     */
    async createTask(data) {
      const res = await createTaskApi(data)
      return res
    },

    /**
     * 更新任务
     */
    async updateTask(id, data) {
      const res = await updateTaskApi(id, data)
      return res
    },

    /**
     * 删除任务
     */
    async deleteTask(id) {
      const res = await deleteTaskApi(id)
      // 从列表中移除
      const index = this.taskList.findIndex(t => t.id === id)
      if (index > -1) {
        this.taskList.splice(index, 1)
        this.total--
      }
      return res
    },

    /**
     * 获取任务实时执行状态
     */
    async fetchLiveStatus(taskId) {
      try {
        const res = await getTaskLiveStatus(taskId)
        this.liveStatusMap[taskId] = res.data
        return res.data
      } catch (error) {
        console.error('获取实时状态失败:', error)
      }
    },

    /**
     * 更新查询参数
     */
    setQueryParams(params) {
      this.queryParams = { ...this.queryParams, ...params }
    },

    /**
     * 重置查询参数
     */
    resetQueryParams() {
      this.queryParams = {
        page: 1,
        pageSize: 20,
        status: '',
        employeeId: '',
        keyword: '',
        date: ''
      }
    }
  }
})
