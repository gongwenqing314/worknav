<template>
  <!-- 任务进度组件：展示任务步骤执行进度 -->
  <div class="task-progress">
    <!-- 任务基本信息 -->
    <div class="task-progress__info">
      <div class="task-info__name">
        <el-tag :type="statusType" size="small">{{ statusLabel }}</el-tag>
        <span class="task-name">{{ taskName }}</span>
      </div>
      <div class="task-info__meta">
        <span><el-icon><User /></el-icon> {{ employeeName }}</span>
        <span><el-icon><Clock /></el-icon> {{ startTime }}</span>
      </div>
    </div>

    <!-- 进度条 -->
    <div class="task-progress__bar">
      <el-progress
        :percentage="progressPercent"
        :status="progressStatus"
        :stroke-width="12"
        :text-inside="true"
      />
    </div>

    <!-- 步骤列表 -->
    <div class="task-progress__steps">
      <div
        v-for="(step, index) in steps"
        :key="step.id || index"
        class="progress-step"
        :class="{
          'progress-step--completed': step.status === 'completed',
          'progress-step--current': step.status === 'current' || step.status === 'in_progress',
          'progress-step--pending': step.status === 'pending' || step.status === 'assigned',
          'progress-step--key': step.isKey
        }"
      >
        <!-- 步骤指示器 -->
        <div class="step-indicator">
          <el-icon v-if="step.status === 'completed'" :size="16"><Check /></el-icon>
          <span v-else-if="step.status === 'current' || step.status === 'in_progress'" class="step-indicator__dot"></span>
          <span v-else class="step-indicator__num">{{ index + 1 }}</span>
        </div>

        <!-- 连接线 -->
        <div v-if="index < steps.length - 1" class="step-connector"></div>

        <!-- 步骤内容 -->
        <div class="step-content">
          <div class="step-content__title">
            <el-icon v-if="step.isKey" color="#F56C6C" :size="14"><Star /></el-icon>
            <span>{{ step.title }}</span>
          </div>
          <div v-if="step.duration" class="step-content__duration">
            耗时 {{ step.duration }}
          </div>
          <div v-if="step.status === 'current' || step.status === 'in_progress'" class="step-content__timer">
            进行中 {{ elapsedTime }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
/**
 * TaskProgress - 任务进度组件
 * 展示任务步骤的执行进度和状态
 */
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { Check, Star, User, Clock } from '@element-plus/icons-vue'
import { TASK_STATUS_LABELS, TASK_STATUS_COLORS } from '@/utils/constants'

const props = defineProps({
  // 任务名称
  taskName: {
    type: String,
    default: ''
  },
  // 员工姓名
  employeeName: {
    type: String,
    default: ''
  },
  // 任务状态
  status: {
    type: String,
    default: 'in_progress'
  },
  // 开始时间
  startTime: {
    type: String,
    default: ''
  },
  // 步骤列表
  steps: {
    type: Array,
    default: () => []
  }
})

// 已用时间
const elapsedTime = ref('00:00')
let timer = null

// 状态标签
const statusLabel = computed(() => TASK_STATUS_LABELS[props.status] || props.status)

// 状态类型
const statusType = computed(() => TASK_STATUS_COLORS[props.status] || 'info')

// 进度百分比
const progressPercent = computed(() => {
  if (!props.steps.length) return 0
  const completed = props.steps.filter(s => s.status === 'completed').length
  return Math.round((completed / props.steps.length) * 100)
})

// 进度条状态
const progressStatus = computed(() => {
  if (props.status === 'completed') return 'success'
  if (props.status === 'cancelled') return 'exception'
  return undefined
})

// 计时器
onMounted(() => {
  if (props.status === 'in_progress') {
    timer = setInterval(() => {
      // 模拟计时 - 实际应从 startedAt 计算
      const parts = elapsedTime.value.split(':')
      let seconds = parseInt(parts[0]) * 60 + parseInt(parts[1]) + 1
      const m = Math.floor(seconds / 60).toString().padStart(2, '0')
      const s = (seconds % 60).toString().padStart(2, '0')
      elapsedTime.value = `${m}:${s}`
    }, 1000)
  }
})

onUnmounted(() => {
  if (timer) clearInterval(timer)
})
</script>

<style scoped>
.task-progress {
  background: #fff;
  border-radius: 8px;
  padding: 16px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
}

/* ===== 任务信息 ===== */
.task-progress__info {
  margin-bottom: 12px;
}

.task-info__name {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 4px;
}

.task-name {
  font-size: 16px;
  font-weight: 600;
  color: #303133;
}

.task-info__meta {
  display: flex;
  gap: 16px;
  font-size: 13px;
  color: #909399;
}

.task-info__meta span {
  display: flex;
  align-items: center;
  gap: 4px;
}

/* ===== 进度条 ===== */
.task-progress__bar {
  margin-bottom: 16px;
}

/* ===== 步骤列表 ===== */
.task-progress__steps {
  display: flex;
  flex-direction: column;
  gap: 0;
}

.progress-step {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  position: relative;
}

.progress-step--key .step-content__title {
  color: #F56C6C;
  font-weight: 600;
}

/* 步骤指示器 */
.step-indicator {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  font-size: 12px;
  font-weight: 600;
  z-index: 1;
}

.progress-step--completed .step-indicator {
  background: #67C23A;
  color: #fff;
}

.progress-step--current .step-indicator {
  background: #409EFF;
  color: #fff;
}

.progress-step--pending .step-indicator {
  background: #E4E7ED;
  color: #909399;
}

.step-indicator__dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #fff;
  animation: blink 1.5s infinite;
}

@keyframes blink {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.3; }
}

/* 连接线 */
.step-connector {
  position: absolute;
  left: 13px;
  top: 28px;
  width: 2px;
  height: calc(100% - 12px);
  background: #E4E7ED;
}

.progress-step--completed .step-connector {
  background: #67C23A;
}

/* 步骤内容 */
.step-content {
  padding-bottom: 16px;
  flex: 1;
  min-width: 0;
}

.step-content__title {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 14px;
  color: #303133;
}

.progress-step--pending .step-content__title {
  color: #C0C4CC;
}

.step-content__duration {
  font-size: 12px;
  color: #909399;
  margin-top: 2px;
}

.step-content__timer {
  font-size: 12px;
  color: #409EFF;
  margin-top: 2px;
  font-variant-numeric: tabular-nums;
}
</style>
