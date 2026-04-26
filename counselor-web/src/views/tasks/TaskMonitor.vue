<template>
  <!-- 任务执行监控页面：实时查看员工任务执行进度 -->
  <div class="task-monitor-page page-container">
    <PageHeader :title="`任务监控 - ${taskName}`" :show-back="true">
      <template #actions>
        <el-button :icon="Refresh" @click="refreshData" :loading="loading">刷新</el-button>
      </template>
    </PageHeader>

    <!-- 监控概览 -->
    <div class="monitor-overview">
      <div class="overview-item">
        <span class="overview-label">分配员工</span>
        <span class="overview-value">{{ executionList.length }} 人</span>
      </div>
      <div class="overview-item">
        <span class="overview-label">已完成</span>
        <span class="overview-value status-success">{{ completedCount }} 人</span>
      </div>
      <div class="overview-item">
        <span class="overview-label">执行中</span>
        <span class="overview-value status-primary">{{ inProgressCount }} 人</span>
      </div>
      <div class="overview-item">
        <span class="overview-label">未开始</span>
        <span class="overview-value status-warning">{{ pendingCount }} 人</span>
      </div>
    </div>

    <!-- 员工执行列表 -->
    <div class="execution-grid">
      <div v-for="exec in executionList" :key="exec.employeeId" class="execution-card card-container">
        <TaskProgress
          :task-name="taskName"
          :employee-name="exec.employeeName"
          :status="exec.status"
          :start-time="exec.startTime"
          :steps="exec.steps"
        />
      </div>
      <el-empty v-if="executionList.length === 0" description="暂无执行记录" />
    </div>

    <!-- 步骤耗时分析 -->
    <div class="card-container mt-lg">
      <h3 class="section-title">步骤耗时分析（卡顿热点）</h3>
      <el-table :data="stepDurationData" stripe size="small">
        <el-table-column prop="stepTitle" label="步骤名称" min-width="140" />
        <el-table-column prop="avgDuration" label="平均耗时" width="120" align="center">
          <template #default="{ row }">{{ row.avgDuration }}秒</template>
        </el-table-column>
        <el-table-column prop="maxDuration" label="最大耗时" width="120" align="center">
          <template #default="{ row }">{{ row.maxDuration }}秒</template>
        </el-table-column>
        <el-table-column label="卡顿指数" width="160">
          <template #default="{ row }">
            <el-progress
              :percentage="row.stuckIndex"
              :color="getStuckColor(row.stuckIndex)"
              :stroke-width="10"
              :text-inside="true"
            />
          </template>
        </el-table-column>
        <el-table-column label="状态" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="row.stuckIndex > 70 ? 'danger' : row.stuckIndex > 40 ? 'warning' : 'success'" size="small">
              {{ row.stuckIndex > 70 ? '高卡顿' : row.stuckIndex > 40 ? '中等' : '正常' }}
            </el-tag>
          </template>
        </el-table-column>
      </el-table>
    </div>
  </div>
</template>

<script setup>
/**
 * TaskMonitor - 任务执行监控页面
 * 实时查看员工任务执行进度、步骤耗时
 */
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRoute } from 'vue-router'
import { Refresh } from '@element-plus/icons-vue'
import PageHeader from '@/components/PageHeader.vue'
import TaskProgress from '@/components/TaskProgress.vue'
import { getTaskDetail, getTaskExecutions } from '@/api/task'

const route = useRoute()
const taskId = route.params.id
const taskName = ref('')
const loading = ref(false)
const executionList = ref([])
let refreshTimer = null

// 步骤耗时数据（从执行记录动态计算）
const stepDurationData = ref([])

// 统计
const completedCount = computed(() => executionList.value.filter(e => e.status === 'completed').length)
const inProgressCount = computed(() => executionList.value.filter(e => e.status === 'in_progress').length)
const pendingCount = computed(() => executionList.value.filter(e => e.status === 'assigned' || e.status === 'pending').length)

function getStuckColor(index) {
  if (index > 70) return '#F56C6C'
  if (index > 40) return '#E6A23C'
  return '#67C23A'
}

/**
 * 根据执行记录动态计算步骤耗时分析
 */
function calculateStepDuration(executions) {
  // 收集所有已完成的步骤耗时，按步骤标题分组
  const stepMap = {}
  for (const exec of executions) {
    for (const step of exec.steps) {
      if (step.status !== 'completed' || !step.duration) continue
      const title = step.title
      const seconds = parseInt(step.duration) || 0
      if (!stepMap[title]) {
        stepMap[title] = { durations: [], maxDuration: 0 }
      }
      stepMap[title].durations.push(seconds)
      if (seconds > stepMap[title].maxDuration) {
        stepMap[title].maxDuration = seconds
      }
    }
  }

  // 计算每个步骤的平均耗时和卡顿指数
  const result = []
  for (const [title, data] of Object.entries(stepMap)) {
    const avgDuration = Math.round(data.durations.reduce((a, b) => a + b, 0) / data.durations.length)
    // 卡顿指数：基于预估时间和实际耗时的比率，预估时间取模板中的 estimated_seconds
    // 简化处理：以最大耗时为基准，超过60秒认为有卡顿风险
    const stuckIndex = Math.min(100, Math.round((avgDuration / Math.max(data.maxDuration, 1)) * 50 + (avgDuration > 60 ? 30 : 0)))
    result.push({ stepTitle: title, avgDuration, maxDuration: data.maxDuration, stuckIndex })
  }

  // 按卡顿指数降序排列
  result.sort((a, b) => b.stuckIndex - a.stuckIndex)
  return result
}

async function refreshData() {
  loading.value = true
  try {
    // 获取任务详情
    const taskRes = await getTaskDetail(taskId)
    taskName.value = taskRes.data?.title || ''

    // 获取执行记录
    const execRes = await getTaskExecutions(taskId, {})
    executionList.value = execRes.data || []

    // 动态计算步骤耗时分析
    stepDurationData.value = calculateStepDuration(executionList.value)
  } catch (error) {
    console.error('获取监控数据失败:', error)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  refreshData()
  // 每 30 秒自动刷新
  refreshTimer = setInterval(refreshData, 30000)
})

onUnmounted(() => {
  if (refreshTimer) clearInterval(refreshTimer)
})
</script>

<style scoped>
/* 监控概览 */
.monitor-overview {
  display: flex;
  gap: 24px;
  padding: 16px 24px;
  background: #fff;
  border-radius: 8px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
  margin-bottom: 16px;
  flex-wrap: wrap;
}

.overview-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
}

.overview-label {
  font-size: 13px;
  color: #909399;
}

.overview-value {
  font-size: 24px;
  font-weight: 700;
  color: #303133;
}

.status-success { color: #67C23A; }
.status-primary { color: #409EFF; }
.status-warning { color: #E6A23C; }

/* 执行卡片网格 */
.execution-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(400px, 1fr));
  gap: 16px;
}

.section-title {
  margin: 0 0 16px;
  font-size: 15px;
  font-weight: 600;
  color: #303133;
}

@media screen and (max-width: 768px) {
  .execution-grid {
    grid-template-columns: 1fr;
  }
}
</style>
