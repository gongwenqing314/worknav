<template>
  <!-- 任务统计页面 -->
  <div class="task-statistics-page page-container">
    <PageHeader title="任务统计">
      <template #actions>
        <el-date-picker
          v-model="dateRange"
          type="daterange"
          range-separator="至"
          start-placeholder="开始日期"
          end-placeholder="结束日期"
          value-format="YYYY-MM-DD"
          @change="fetchData"
        />
        <el-button :icon="Refresh" @click="fetchData">刷新</el-button>
      </template>
    </PageHeader>

    <!-- 概览卡片 -->
    <div class="stat-cards">
      <StatCard title="总任务数" :value="stats.totalTasks" icon="List" color="#409EFF" />
      <StatCard title="完成率" :value="stats.completionRate + '%'" icon="CircleCheck" color="#67C23A" :trend="stats.completionTrend" />
      <StatCard title="平均耗时" :value="stats.avgDuration" icon="Timer" color="#E6A23C" />
      <StatCard title="卡顿次数" :value="stats.stuckCount" icon="Warning" color="#F56C6C" />
    </div>

    <!-- 图表区域 -->
    <div class="charts-grid">
      <!-- 任务完成率趋势 -->
      <div class="card-container">
        <h3 class="section-title">任务完成率趋势</h3>
        <div ref="trendChartRef" class="chart-container" v-loading="chartLoading"></div>
      </div>

      <!-- 任务状态分布 -->
      <div class="card-container">
        <h3 class="section-title">任务状态分布</h3>
        <div ref="statusChartRef" class="chart-container" v-loading="chartLoading"></div>
      </div>
    </div>

    <!-- 员工排行 -->
    <div class="card-container mt-md">
      <h3 class="section-title">员工任务完成排行</h3>
      <el-table :data="employeeRanking" stripe size="small">
        <el-table-column type="index" label="排名" width="70" align="center">
          <template #default="{ $index }">
            <el-tag v-if="$index < 3" :type="['success', '', 'warning'][$index]" size="small" effect="dark" round>
              {{ $index + 1 }}
            </el-tag>
            <span v-else>{{ $index + 1 }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="name" label="员工" width="100" />
        <el-table-column prop="totalTasks" label="总任务" width="80" align="center" />
        <el-table-column prop="completedTasks" label="完成数" width="80" align="center" />
        <el-table-column label="完成率" width="160">
          <template #default="{ row }">
            <el-progress :percentage="row.completionRate" :stroke-width="10" :text-inside="true" />
          </template>
        </el-table-column>
        <el-table-column prop="avgDuration" label="平均耗时" width="100" align="center" />
      </el-table>
    </div>

    <!-- 快捷入口 -->
    <div class="quick-links mt-md">
      <el-button @click="$router.push('/statistics/step-duration')">步骤耗时分析</el-button>
      <el-button @click="$router.push('/statistics/emotion')">情绪统计</el-button>
      <el-button @click="$router.push('/statistics/report-export')">报表导出</el-button>
    </div>
  </div>
</template>

<script setup>
/**
 * TaskStatistics - 任务统计页面
 */
import { ref, reactive, onMounted, onUnmounted, nextTick } from 'vue'
import * as echarts from 'echarts'
import { Refresh } from '@element-plus/icons-vue'
import PageHeader from '@/components/PageHeader.vue'
import StatCard from '@/components/StatCard.vue'
import { getTaskCompletionTrend } from '@/api/statistics'
import dayjs from 'dayjs'

const dateRange = ref([dayjs().subtract(30, 'day').format('YYYY-MM-DD'), dayjs().format('YYYY-MM-DD')])
const chartLoading = ref(false)
const trendChartRef = ref(null)
const statusChartRef = ref(null)
let trendChart = null
let statusChart = null

const stats = reactive({
  totalTasks: 0,
  completionRate: 0,
  completionTrend: 0,
  avgDuration: '0分钟',
  stuckCount: 0
})

const employeeRanking = ref([])

function initCharts() {
  if (trendChartRef.value) trendChart = echarts.init(trendChartRef.value)
  if (statusChartRef.value) statusChart = echarts.init(statusChartRef.value)
}

function renderTrendChart() {
  if (!trendChart) return
  const dates = []
  const data = []
  for (let i = 29; i >= 0; i--) {
    dates.push(dayjs().subtract(i, 'day').format('MM-DD'))
    data.push(0) // 后端暂无逐日趋势数据，用 0 占位
  }
  trendChart.setOption({
    tooltip: { trigger: 'axis' },
    grid: { left: '3%', right: '4%', bottom: '8%', top: '8%', containLabel: true },
    xAxis: { type: 'category', data: dates, boundaryGap: false },
    yAxis: { type: 'value', name: '完成率(%)', min: 0, max: 100 },
    series: [{ type: 'line', smooth: true, data, areaStyle: { color: 'rgba(64, 158, 255, 0.1)' }, itemStyle: { color: '#409EFF' } }]
  }, true)
}

function renderStatusChart(completed = 0, inProgress = 0, pending = 0) {
  if (!statusChart) return
  statusChart.setOption({
    tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
    legend: { bottom: 0 },
    series: [{
      type: 'pie', radius: ['35%', '65%'], center: ['50%', '45%'],
      data: [
        { value: completed, name: '已完成', itemStyle: { color: '#67C23A' } },
        { value: inProgress, name: '执行中', itemStyle: { color: '#409EFF' } },
        { value: pending, name: '未完成', itemStyle: { color: '#F56C6C' } }
      ]
    }]
  }, true)
}

async function fetchData() {
  chartLoading.value = true
  try {
    // 获取任务完成率统计
    const res = await getTaskCompletionTrend({ range: 'month' })
    const data = res.data || {}

    // 更新概览卡片
    stats.totalTasks = data.total || 0
    stats.completionRate = data.completionRate || 0
    stats.stuckCount = data.byStatus?.['in_progress'] || 0

    // 更新饼图数据
    const byStatus = data.byStatus || {}
    renderStatusChart(
      byStatus['completed'] || 0,
      byStatus['in_progress'] || 0,
      (byStatus['assigned'] || 0) + (byStatus['pending'] || 0)
    )

    // 趋势图暂用 0 占位（后端暂无逐日数据）
    renderTrendChart()
  } catch (error) {
    console.error('获取统计数据失败:', error)
    renderTrendChart()
    renderStatusChart(0, 0, 0)
  } finally {
    chartLoading.value = false
  }
}

const handleResize = () => { trendChart?.resize(); statusChart?.resize() }

onMounted(() => {
  nextTick(() => { initCharts(); fetchData() })
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
  trendChart?.dispose(); statusChart?.dispose()
})
</script>

<style scoped>
.stat-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
  margin-bottom: 16px;
}

.charts-grid {
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
  height: 300px;
}

.quick-links {
  display: flex;
  gap: 12px;
  justify-content: center;
}

@media screen and (max-width: 768px) {
  .charts-grid { grid-template-columns: 1fr; }
}
</style>
