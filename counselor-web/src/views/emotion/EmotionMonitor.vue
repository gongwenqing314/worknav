<template>
  <!-- 情绪监控面板：实时情绪状态、趋势图表、预警列表 -->
  <div class="emotion-monitor-page page-container">
    <PageHeader title="情绪监控">
      <template #actions>
        <el-button :icon="Refresh" @click="refreshData" :loading="loading">刷新</el-button>
        <el-button type="primary" @click="$router.push('/emotion/alert-rules')">预警规则配置</el-button>
      </template>
    </PageHeader>

    <!-- 情绪概览 -->
    <div class="emotion-overview">
      <div v-for="(info, key) in emotionOverview" :key="key" class="emotion-overview-item" :style="{ borderTopColor: info.color }">
        <div class="emotion-icon" :style="{ backgroundColor: info.color + '15', color: info.color }">
          <el-icon :size="24"><component :is="info.icon" /></el-icon>
        </div>
        <div class="emotion-info">
          <div class="emotion-count">{{ info.count }}</div>
          <div class="emotion-label">{{ info.label }}</div>
        </div>
      </div>
    </div>

    <div class="emotion-grid">
      <!-- 情绪趋势图 -->
      <div class="card-container">
        <EmotionChart title="情绪趋势" height="320px" />
      </div>

      <!-- 实时情绪状态 -->
      <div class="card-container">
        <h3 class="section-title">员工实时情绪</h3>
        <div class="employee-emotion-list">
          <div v-for="emp in employeeEmotions" :key="emp.id" class="employee-emotion-item">
            <el-avatar :size="36" icon="UserFilled" />
            <div class="employee-emotion-info">
              <span class="employee-name">{{ emp.name }}</span>
              <span class="employee-task">{{ emp.currentTask }}</span>
            </div>
            <div class="emotion-badge" :style="{ backgroundColor: emp.emotionColor + '15', color: emp.emotionColor }">
              {{ emp.emotionLabel }}
            </div>
            <span class="emotion-time">{{ emp.updateTime }}</span>
          </div>
          <el-empty v-if="employeeEmotions.length === 0" description="暂无数据" :image-size="60" />
        </div>
      </div>

      <!-- 预警列表 -->
      <div class="card-container">
        <div class="card-header-row">
          <h3 class="section-title">预警列表</h3>
          <el-select v-model="alertFilter" size="small" style="width: 100px" @change="fetchAlerts">
            <el-option label="全部" value="" />
            <el-option label="未处理" value="unhandled" />
            <el-option label="已处理" value="handled" />
          </el-select>
        </div>
        <div class="alert-list">
          <div v-for="alert in alertList" :key="alert.id" class="alert-item" :class="`alert-item--${alert.level}`">
            <div class="alert-left">
              <el-tag :type="alert.levelType" size="small" effect="dark">{{ alert.levelLabel }}</el-tag>
              <div class="alert-detail">
                <span class="alert-employee">{{ alert.employeeName }}</span>
                <span class="alert-desc">{{ alert.description }}</span>
              </div>
            </div>
            <div class="alert-right">
              <span class="alert-time">{{ alert.time }}</span>
              <el-button
                v-if="!alert.handled"
                size="small"
                type="primary"
                text
                @click="handleAlert(alert)"
              >
                处理
              </el-button>
              <el-tag v-else type="success" size="small">已处理</el-tag>
            </div>
          </div>
          <el-empty v-if="alertList.length === 0" description="暂无预警" :image-size="60" />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
/**
 * EmotionMonitor - 情绪监控面板
 * 实时情绪状态、趋势图表、预警列表
 */
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Refresh } from '@element-plus/icons-vue'
import PageHeader from '@/components/PageHeader.vue'
import EmotionChart from '@/components/EmotionChart.vue'
import { getEmotionOverview, getEmotionAlerts, handleAlert as handleAlertApi } from '@/api/emotion'
import { EMOTION_LABELS, EMOTION_COLORS } from '@/utils/constants'

const loading = ref(false)
const alertFilter = ref('')

// 情绪概览
const emotionOverview = reactive({
  happy: { count: 12, label: '开心', color: EMOTION_COLORS.happy, icon: 'Sunny' },
  calm: { count: 8, label: '平静', color: EMOTION_COLORS.calm, icon: 'Moon' },
  anxious: { count: 3, label: '焦虑', color: EMOTION_COLORS.anxious, icon: 'Warning' },
  angry: { count: 1, label: '愤怒', color: EMOTION_COLORS.angry, icon: 'Lightning' },
  sad: { count: 2, label: '悲伤', color: EMOTION_COLORS.sad, icon: 'Cloudy' },
  confused: { count: 1, label: '困惑', color: EMOTION_COLORS.confused, icon: 'QuestionFilled' }
})

// 员工实时情绪
const employeeEmotions = ref([
  { id: '1', name: '张三', currentTask: '办公室清洁', emotionLabel: '开心', emotionColor: '#67C23A', updateTime: '10:30' },
  { id: '2', name: '李四', currentTask: '文件整理', emotionLabel: '平静', emotionColor: '#409EFF', updateTime: '10:28' },
  { id: '3', name: '王五', currentTask: '物料搬运', emotionLabel: '焦虑', emotionColor: '#E6A23C', updateTime: '10:25' },
  { id: '4', name: '赵六', currentTask: '包装作业', emotionLabel: '开心', emotionColor: '#67C23A', updateTime: '10:20' }
])

// 预警列表
const alertList = ref([
  { id: '1', level: 'high', levelType: 'danger', levelLabel: '高', employeeName: '王五', description: '连续焦虑超过30分钟', time: '10:25', handled: false },
  { id: '2', level: 'medium', levelType: 'warning', levelLabel: '中', employeeName: '张三', description: '情绪从开心转为焦虑', time: '09:50', handled: false },
  { id: '3', level: 'low', levelType: 'info', levelLabel: '低', employeeName: '赵六', description: '任务卡顿超过5分钟', time: '09:30', handled: true }
])

async function refreshData() {
  loading.value = true
  try {
    const res = await getEmotionOverview()
    if (res.data) {
      // 更新情绪概览数据
      Object.keys(res.data).forEach(key => {
        if (emotionOverview[key]) {
          emotionOverview[key].count = res.data[key]
        }
      })
    }
  } catch (error) {
    console.error('获取情绪概览失败:', error)
  } finally {
    loading.value = false
  }
  fetchAlerts()
}

async function fetchAlerts() {
  try {
    const res = await getEmotionAlerts({ handled: alertFilter.value })
    if (res.data?.list) {
      alertList.value = res.data.list
    }
  } catch (error) {
    console.error('获取预警列表失败:', error)
  }
}

async function handleAlert(alert) {
  try {
    await handleAlertApi(alert.id, { action: 'acknowledged', note: '已查看' })
    alert.handled = true
    ElMessage.success('预警已处理')
  } catch (error) {
    console.error('处理预警失败:', error)
  }
}

onMounted(() => {
  refreshData()
})
</script>

<style scoped>
/* 情绪概览 */
.emotion-overview {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 12px;
  margin-bottom: 16px;
}

.emotion-overview-item {
  background: #fff;
  border-radius: 8px;
  padding: 16px;
  display: flex;
  align-items: center;
  gap: 12px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
  border-top: 3px solid;
}

.emotion-icon {
  width: 44px;
  height: 44px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.emotion-count {
  font-size: 22px;
  font-weight: 700;
  color: #303133;
}

.emotion-label {
  font-size: 13px;
  color: #909399;
}

/* 网格布局 */
.emotion-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.section-title {
  margin: 0 0 12px;
  font-size: 15px;
  font-weight: 600;
  color: #303133;
}

.card-header-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
}

.card-header-row .section-title {
  margin-bottom: 0;
}

/* 员工情绪列表 */
.employee-emotion-list {
  max-height: 350px;
  overflow-y: auto;
}

.employee-emotion-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 0;
  border-bottom: 1px solid #f0f0f0;
}

.employee-emotion-item:last-child { border-bottom: none; }

.employee-emotion-info {
  flex: 1;
  min-width: 0;
}

.employee-name {
  display: block;
  font-size: 14px;
  font-weight: 500;
  color: #303133;
}

.employee-task {
  display: block;
  font-size: 12px;
  color: #909399;
}

.emotion-badge {
  padding: 3px 10px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 500;
  white-space: nowrap;
}

.emotion-time {
  font-size: 12px;
  color: #C0C4CC;
  white-space: nowrap;
}

/* 预警列表 */
.alert-list {
  max-height: 350px;
  overflow-y: auto;
}

.alert-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 0;
  border-bottom: 1px solid #f0f0f0;
}

.alert-item:last-child { border-bottom: none; }

.alert-left {
  display: flex;
  align-items: center;
  gap: 8px;
  flex: 1;
  min-width: 0;
}

.alert-detail {
  display: flex;
  flex-direction: column;
}

.alert-employee {
  font-size: 14px;
  font-weight: 500;
  color: #303133;
}

.alert-desc {
  font-size: 12px;
  color: #909399;
}

.alert-right {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-shrink: 0;
}

.alert-time {
  font-size: 12px;
  color: #C0C4CC;
  white-space: nowrap;
}

@media screen and (max-width: 1024px) {
  .emotion-grid {
    grid-template-columns: 1fr;
  }
}
</style>
