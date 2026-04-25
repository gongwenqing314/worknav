<template>
  <!-- 首页仪表盘：关键指标、待办事项、快捷入口 -->
  <div class="dashboard-page page-container">
    <!-- 关键指标卡片 -->
  <div class="stat-cards">
    <StatCard
      title="员工总数"
      :value="stats.employeeCount"
      icon="User"
      color="#409EFF"
      :trend="stats.employeeTrend"
    />
    <StatCard
      title="今日任务"
      :value="typeof stats.todayTasks === 'object' ? stats.todayTasks.total : stats.todayTasks"
      icon="List"
      color="#67C23A"
      :trend="stats.taskTrend"
    />
    <StatCard
      title="执行中"
      :value="typeof stats.todayTasks === 'object' ? (stats.todayTasks.inProgress || 0) : stats.inProgressTasks"
      icon="Loading"
      color="#E6A23C"
    />
    <StatCard
      title="情绪预警"
      :value="stats.alertCount || (stats.todayEmotionAlerts || 0)"
      icon="Warning"
      color="#F56C6C"
    />
    <StatCard
      title="任务完成率"
      :value="stats.completionRate + '%'"
      icon="CircleCheck"
      color="#67C23A"
      :trend="stats.completionTrend"
    />
  </div>

    <div class="dashboard-grid">
      <!-- 待办事项 -->
      <div class="card-container dashboard-todo">
        <div class="card-header">
          <h3>待办事项</h3>
          <el-tag type="info" size="small">{{ todoList.length }} 项</el-tag>
        </div>
        <div class="todo-list">
          <div v-for="todo in todoList" :key="todo.id" class="todo-item" :class="{ 'todo-item--urgent': todo.urgent }">
            <el-checkbox v-model="todo.done" @change="handleTodoChange(todo)">
              <span class="todo-text">{{ todo.text }}</span>
            </el-checkbox>
            <span class="todo-time">{{ todo.time }}</span>
          </div>
          <el-empty v-if="todoList.length === 0" description="暂无待办事项" :image-size="60" />
        </div>
      </div>

      <!-- 快捷入口 -->
      <div class="card-container dashboard-shortcuts">
        <div class="card-header">
          <h3>快捷入口</h3>
        </div>
        <div class="shortcut-grid">
          <div class="shortcut-item" @click="$router.push('/employees')">
            <el-icon :size="28" color="#409EFF"><User /></el-icon>
            <span>员工管理</span>
          </div>
          <div class="shortcut-item" @click="$router.push('/tasks/create')">
            <el-icon :size="28" color="#67C23A"><Plus /></el-icon>
            <span>创建任务</span>
          </div>
          <div class="shortcut-item" @click="$router.push('/tasks')">
            <el-icon :size="28" color="#E6A23C"><Monitor /></el-icon>
            <span>任务监控</span>
          </div>
          <div class="shortcut-item" @click="$router.push('/schedule')">
            <el-icon :size="28" color="#909399"><Calendar /></el-icon>
            <span>排班管理</span>
          </div>
          <div class="shortcut-item" @click="$router.push('/emotion')">
            <el-icon :size="28" color="#F56C6C"><Sunny /></el-icon>
            <span>情绪监控</span>
          </div>
          <div class="shortcut-item" @click="$router.push('/remote-assist')">
            <el-icon :size="28" color="#B37FEB"><VideoCamera /></el-icon>
            <span>远程协助</span>
          </div>
          <div class="shortcut-item" @click="$router.push('/notifications')">
            <el-icon :size="28" color="#409EFF"><Bell /></el-icon>
            <span>通知中心</span>
          </div>
          <div class="shortcut-item" @click="$router.push('/statistics')">
            <el-icon :size="28" color="#67C23A"><DataAnalysis /></el-icon>
            <span>数据统计</span>
          </div>
        </div>
      </div>

      <!-- 今日任务概览 -->
      <div class="card-container dashboard-tasks">
        <div class="card-header">
          <h3>今日任务概览</h3>
          <el-button text type="primary" @click="$router.push('/tasks')">查看全部</el-button>
        </div>
        <el-table :data="todayTasks" stripe size="small" max-height="300">
          <el-table-column prop="employeeName" label="员工" width="80" />
          <el-table-column prop="taskName" label="任务名称" show-overflow-tooltip />
          <el-table-column label="进度" width="120">
            <template #default="{ row }">
              <el-progress :percentage="row.progress" :stroke-width="8" :text-inside="true" />
            </template>
          </el-table-column>
          <el-table-column label="状态" width="80" align="center">
            <template #default="{ row }">
              <el-tag :type="row.statusType" size="small">{{ row.statusLabel }}</el-tag>
            </template>
          </el-table-column>
        </el-table>
      </div>

      <!-- 最近预警 -->
      <div class="card-container dashboard-alerts">
        <div class="card-header">
          <h3>最近预警</h3>
          <el-button text type="primary" @click="$router.push('/emotion')">查看全部</el-button>
        </div>
        <div class="alert-list">
          <div v-for="alert in recentAlerts" :key="alert.id" class="alert-item">
            <div class="alert-info">
              <el-tag :type="alert.levelType" size="small" effect="dark">{{ alert.level }}</el-tag>
              <span class="alert-employee">{{ alert.employeeName }}</span>
              <span class="alert-desc">{{ alert.description }}</span>
            </div>
            <span class="alert-time">{{ alert.time }}</span>
          </div>
          <el-empty v-if="recentAlerts.length === 0" description="暂无预警" :image-size="60" />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
/**
 * DashboardView - 首页仪表盘
 * 展示关键指标、待办事项、快捷入口、今日任务、最近预警
 */
import { ref, reactive, onMounted } from 'vue'
import StatCard from '@/components/StatCard.vue'
import { getDashboardStats } from '@/api/statistics'

// 关键指标数据
const stats = reactive({
  employeeCount: 0,
  employeeTrend: 0,
  todayTasks: 0,
  taskTrend: 0,
  inProgressTasks: 0,
  alertCount: 0,
  completionRate: 0,
  completionTrend: 0
})

// 待办事项
const todoList = ref([
  { id: 1, text: '审核新员工张三的档案', done: false, urgent: true, time: '10:00' },
  { id: 2, text: '为李四创建清洁任务', done: false, urgent: false, time: '11:00' },
  { id: 3, text: '处理情绪预警（王五）', done: false, urgent: true, time: '14:00' },
  { id: 4, text: '更新沟通板常用语', done: false, urgent: false, time: '15:00' },
  { id: 5, text: '查看本周排班表', done: true, urgent: false, time: '09:00' }
])

// 今日任务列表
const todayTasks = ref([
  { employeeName: '张三', taskName: '办公室清洁', progress: 75, statusLabel: '执行中', statusType: 'primary' },
  { employeeName: '李四', taskName: '文件整理', progress: 100, statusLabel: '已完成', statusType: 'success' },
  { employeeName: '王五', taskName: '物料搬运', progress: 30, statusLabel: '执行中', statusType: 'primary' },
  { employeeName: '赵六', taskName: '包装作业', progress: 0, statusLabel: '待执行', statusType: 'warning' }
])

// 最近预警
const recentAlerts = ref([
  { id: 1, level: '高', levelType: 'danger', employeeName: '王五', description: '连续焦虑超过30分钟', time: '14:30' },
  { id: 2, level: '中', levelType: 'warning', employeeName: '张三', description: '情绪波动异常', time: '11:20' },
  { id: 3, level: '低', levelType: 'info', employeeName: '赵六', description: '任务卡顿超过5分钟', time: '10:15' }
])

/**
 * 获取仪表盘统计数据
 */
async function fetchDashboardData() {
  try {
    const res = await getDashboardStats()
    if (res.data) {
      Object.assign(stats, res.data)
    }
  } catch (error) {
    // 使用模拟数据作为后备
    stats.employeeCount = 24
    stats.employeeTrend = 8
    stats.todayTasks = 12
    stats.taskTrend = 15
    stats.inProgressTasks = 5
    stats.alertCount = 3
    stats.completionRate = 85
    stats.completionTrend = 5
  }
}

/**
 * 待办事项状态变更
 */
function handleTodoChange(todo) {
  console.log('待办事项状态变更:', todo)
}

onMounted(() => {
  fetchDashboardData()
})
</script>

<style scoped>
/* ===== 统计卡片行 ===== */
.stat-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
  margin-bottom: 24px;
}

/* ===== 仪表盘网格 ===== */
.dashboard-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
}

.card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16px;
}

.card-header h3 {
  margin: 0;
  font-size: 16px;
  color: #303133;
}

/* ===== 待办事项 ===== */
.todo-list {
  max-height: 300px;
  overflow-y: auto;
}

.todo-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 0;
  border-bottom: 1px solid #f0f0f0;
}

.todo-item:last-child {
  border-bottom: none;
}

.todo-item--urgent .todo-text {
  color: #F56C6C;
  font-weight: 500;
}

.todo-text {
  font-size: 14px;
  color: #303133;
}

.todo-time {
  font-size: 12px;
  color: #C0C4CC;
  white-space: nowrap;
  margin-left: 12px;
}

/* ===== 快捷入口 ===== */
.shortcut-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
}

.shortcut-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  padding: 16px 8px;
  border-radius: 8px;
  cursor: pointer;
  transition: background 0.2s;
}

.shortcut-item:hover {
  background: #f5f7fa;
}

.shortcut-item span {
  font-size: 13px;
  color: #606266;
}

/* ===== 预警列表 ===== */
.alert-list {
  max-height: 300px;
  overflow-y: auto;
}

.alert-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 0;
  border-bottom: 1px solid #f0f0f0;
}

.alert-item:last-child {
  border-bottom: none;
}

.alert-info {
  display: flex;
  align-items: center;
  gap: 8px;
  flex: 1;
  min-width: 0;
}

.alert-employee {
  font-weight: 500;
  color: #303133;
  white-space: nowrap;
}

.alert-desc {
  font-size: 13px;
  color: #909399;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.alert-time {
  font-size: 12px;
  color: #C0C4CC;
  white-space: nowrap;
  margin-left: 12px;
}

/* ===== 响应式 ===== */
@media screen and (max-width: 1024px) {
  .dashboard-grid {
    grid-template-columns: 1fr;
  }
}

@media screen and (max-width: 768px) {
  .stat-cards {
    grid-template-columns: repeat(2, 1fr);
  }

  .shortcut-grid {
    grid-template-columns: repeat(3, 1fr);
  }
}

@media screen and (max-width: 480px) {
  .stat-cards {
    grid-template-columns: 1fr;
  }

  .shortcut-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}
</style>
