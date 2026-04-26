<template>
  <!-- 情绪统计页面 -->
  <div class="emotion-statistics-page page-container">
    <PageHeader title="情绪统计" :show-back="true">
      <template #actions>
        <el-select v-model="selectedEmployee" placeholder="选择员工" clearable style="width: 160px" @change="fetchData">
          <el-option v-for="emp in employeeOptions" :key="emp.id" :label="emp.name" :value="emp.id" />
        </el-select>
        <el-date-picker v-model="dateRange" type="daterange" range-separator="至" start-placeholder="开始" end-placeholder="结束" value-format="YYYY-MM-DD" @change="fetchData" />
      </template>
    </PageHeader>

    <div class="emotion-stats-grid">
      <!-- 情绪趋势图 -->
      <div class="card-container">
        <EmotionChart :title="selectedEmployee ? '个人情绪趋势' : '整体情绪趋势'" :employee-id="selectedEmployee" height="320px" />
      </div>

      <!-- 情绪分布饼图 -->
      <div class="card-container">
        <h3 class="section-title">情绪分布</h3>
        <div ref="pieChartRef" class="chart-container"></div>
      </div>
    </div>

    <!-- 情绪变化明细 -->
    <div class="card-container mt-md">
      <h3 class="section-title">情绪变化明细</h3>
      <el-table :data="emotionRecords" stripe size="small" max-height="400">
        <el-table-column prop="employeeName" label="员工" width="100" />
        <el-table-column prop="taskName" label="当前任务" width="140" />
        <el-table-column label="情绪" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="getEmotionTagType(row.emotion)" size="small">
              {{ EMOTION_LABELS[row.emotion] || row.emotion }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="duration" label="持续时间" width="100" align="center" />
        <el-table-column prop="trigger" label="触发原因" min-width="160" show-overflow-tooltip />
        <el-table-column prop="recordedAt" label="记录时间" width="170" />
      </el-table>
    </div>
  </div>
</template>

<script setup>
/**
 * EmotionStatistics - 情绪统计页面
 */
import { ref, onMounted, onUnmounted, nextTick } from 'vue'
import * as echarts from 'echarts'
import PageHeader from '@/components/PageHeader.vue'
import EmotionChart from '@/components/EmotionChart.vue'
import { getEmotionStatistics } from '@/api/statistics'
import { EMOTION_LABELS, EMOTION_COLORS } from '@/utils/constants'
import { getEmployeeList } from '@/api/user'
import dayjs from 'dayjs'

const selectedEmployee = ref('')
const dateRange = ref([dayjs().subtract(30, 'day').format('YYYY-MM-DD'), dayjs().format('YYYY-MM-DD')])
const employeeOptions = ref([])
const emotionRecords = ref([])
const pieChartRef = ref(null)
let pieChart = null

function getEmotionTagType(emotion) {
  const map = { happy: 'success', calm: '', anxious: 'warning', angry: 'danger', sad: 'info', confused: 'warning' }
  return map[emotion] || 'info'
}

function renderPieChart() {
  if (!pieChartRef.value) return
  if (!pieChart) pieChart = echarts.init(pieChartRef.value)
  const keys = Object.keys(EMOTION_LABELS)
  // 从情绪记录中统计分布
  const counts = {}
  for (const r of emotionRecords.value) {
    if (r.emotion_type || r.emotion) {
      const key = r.emotion_type || r.emotion
      counts[key] = (counts[key] || 0) + 1
    }
  }
  pieChart.setOption({
    tooltip: { trigger: 'item', formatter: '{b}: {c}次 ({d}%)' },
    legend: { orient: 'vertical', right: '5%', top: 'center' },
    series: [{
      type: 'pie', radius: ['35%', '65%'], center: ['35%', '50%'],
      data: keys.map(k => ({
        name: EMOTION_LABELS[k],
        value: counts[k] || 0,
        itemStyle: { color: EMOTION_COLORS[k] }
      }))
    }]
  }, true)
}

async function fetchData() {
  try {
    const res = await getEmotionStatistics({
      employeeId: selectedEmployee.value,
      startDate: dateRange.value?.[0],
      endDate: dateRange.value?.[1]
    })
    emotionRecords.value = res.data?.records || []
  } catch (error) {
    console.error('获取情绪统计数据失败:', error)
    emotionRecords.value = []
  }
  renderPieChart()
}

const handleResize = () => pieChart?.resize()

onMounted(async () => {
  try {
    const res = await getEmployeeList({ page: 1, pageSize: 100 })
    employeeOptions.value = res.data?.list || []
  } catch (error) { console.error(error) }
  nextTick(() => fetchData())
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
  pieChart?.dispose()
})
</script>

<style scoped>
.emotion-stats-grid {
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

.chart-container {
  width: 100%;
  height: 320px;
}

@media screen and (max-width: 768px) {
  .emotion-stats-grid { grid-template-columns: 1fr; }
}
</style>
