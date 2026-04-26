<template>
  <!-- 步骤耗时分析页面（卡顿热点） -->
  <div class="step-duration-page page-container">
    <PageHeader title="步骤耗时分析" :show-back="true">
      <template #actions>
        <el-select v-model="selectedTask" placeholder="选择任务" style="width: 200px" @change="fetchData">
          <el-option v-for="t in taskOptions" :key="t.id" :label="t.title" :value="t.id" />
        </el-select>
        <el-date-picker v-model="dateRange" type="daterange" range-separator="至" start-placeholder="开始" end-placeholder="结束" value-format="YYYY-MM-DD" @change="fetchData" />
      </template>
    </PageHeader>

    <!-- 卡顿热点排行 -->
    <div class="card-container">
      <h3 class="section-title">卡顿热点排行</h3>
      <el-table :data="stuckSteps" v-loading="loading" stripe :default-sort="{ prop: 'stuckIndex', order: 'descending' }">
        <el-table-column type="index" label="排名" width="70" align="center">
          <template #default="{ $index }">
            <el-tag v-if="$index < 3" :type="['danger', 'warning', 'warning'][$index]" size="small" effect="dark" round>
              {{ $index + 1 }}
            </el-tag>
            <span v-else>{{ $index + 1 }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="stepTitle" label="步骤名称" min-width="160" />
        <el-table-column prop="taskName" label="所属任务" width="140" />
        <el-table-column prop="execCount" label="执行次数" width="100" align="center" />
        <el-table-column prop="avgDuration" label="平均耗时" width="120" align="center">
          <template #default="{ row }">{{ row.avgDuration }}秒</template>
        </el-table-column>
        <el-table-column prop="maxDuration" label="最大耗时" width="120" align="center">
          <template #default="{ row }">{{ row.maxDuration }}秒</template>
        </el-table-column>
        <el-table-column prop="stuckIndex" label="卡顿指数" width="180" sortable>
          <template #default="{ row }">
            <el-progress
              :percentage="row.stuckIndex"
              :color="row.stuckIndex > 70 ? '#F56C6C' : row.stuckIndex > 40 ? '#E6A23C' : '#67C23A'"
              :stroke-width="12"
              :text-inside="true"
            />
          </template>
        </el-table-column>
        <el-table-column label="建议" width="120">
          <template #default="{ row }">
            <el-button size="small" text type="primary" @click="showSuggestion(row)">查看建议</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 耗时分布图 -->
    <div class="card-container mt-md">
      <h3 class="section-title">步骤耗时分布</h3>
      <div ref="chartRef" class="chart-container" v-loading="loading"></div>
    </div>

    <!-- 建议对话框 -->
    <el-dialog v-model="suggestionVisible" title="优化建议" width="500px">
      <div v-if="currentStep" class="suggestion-content">
        <h4>{{ currentStep.stepTitle }}</h4>
        <p class="suggestion-desc">该步骤平均耗时 {{ currentStep.avgDuration }} 秒，卡顿指数 {{ currentStep.stuckIndex }}。</p>
        <div class="suggestion-list">
          <div class="suggestion-item">
            <el-icon color="#409EFF"><InfoFilled /></el-icon>
            <span>建议为该步骤添加更详细的图片指引</span>
          </div>
          <div class="suggestion-item">
            <el-icon color="#409EFF"><InfoFilled /></el-icon>
            <span>考虑将该步骤拆分为更小的子步骤</span>
          </div>
          <div class="suggestion-item">
            <el-icon color="#409EFF"><InfoFilled /></el-icon>
            <span>建议录制语音指导辅助理解</span>
          </div>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script setup>
/**
 * StepDuration - 步骤耗时分析页面（卡顿热点）
 */
import { ref, onMounted, onUnmounted, nextTick } from 'vue'
import * as echarts from 'echarts'
import { InfoFilled } from '@element-plus/icons-vue'
import PageHeader from '@/components/PageHeader.vue'
import { getStepDurationAnalysis } from '@/api/statistics'
import { getTaskList } from '@/api/task'
import dayjs from 'dayjs'

const loading = ref(false)
const selectedTask = ref('')
const dateRange = ref([dayjs().subtract(30, 'day').format('YYYY-MM-DD'), dayjs().format('YYYY-MM-DD')])
const taskOptions = ref([])
const stuckSteps = ref([])
const chartRef = ref(null)
let chart = null
const suggestionVisible = ref(false)
const currentStep = ref(null)

async function fetchTaskOptions() {
  try {
    const res = await getTaskList({ page: 1, pageSize: 100 })
    taskOptions.value = res.data?.list || []
  } catch (error) { console.error(error) }
}

async function fetchData() {
  loading.value = true
  try {
    const res = await getStepDurationAnalysis({
      taskId: selectedTask.value,
      startDate: dateRange.value?.[0],
      endDate: dateRange.value?.[1],
      topN: 20
    })
    stuckSteps.value = res.data || []
  } catch (error) {
    console.error('获取步骤耗时数据失败:', error)
    stuckSteps.value = []
  } finally {
    loading.value = false
    renderChart()
  }
}

function renderChart() {
  if (!chartRef.value) return
  if (!chart) chart = echarts.init(chartRef.value)
  const steps = stuckSteps.value.slice(0, 10)
  chart.setOption({
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
    grid: { left: '3%', right: '4%', bottom: '8%', top: '8%', containLabel: true },
    xAxis: { type: 'category', data: steps.map(s => s.stepTitle), axisLabel: { rotate: 30 } },
    yAxis: { type: 'value', name: '耗时(秒)' },
    series: [
      { name: '平均耗时', type: 'bar', data: steps.map(s => s.avgDuration), itemStyle: { color: '#409EFF' } },
      { name: '最大耗时', type: 'bar', data: steps.map(s => s.maxDuration), itemStyle: { color: '#F56C6C' } }
    ]
  }, true)
}

function showSuggestion(row) {
  currentStep.value = row
  suggestionVisible.value = true
}

const handleResize = () => chart?.resize()

onMounted(() => {
  fetchTaskOptions()
  nextTick(() => fetchData())
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
  chart?.dispose()
})
</script>

<style scoped>
.section-title {
  margin: 0 0 12px;
  font-size: 15px;
  font-weight: 600;
  color: #303133;
}

.chart-container {
  width: 100%;
  height: 350px;
}

.suggestion-content h4 {
  margin: 0 0 8px;
  font-size: 16px;
  color: #303133;
}

.suggestion-desc {
  font-size: 14px;
  color: #606266;
  margin-bottom: 16px;
}

.suggestion-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.suggestion-item {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
  color: #606266;
  padding: 8px 12px;
  background: #f5f7fa;
  border-radius: 6px;
}
</style>
