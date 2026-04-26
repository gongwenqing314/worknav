<template>
  <!-- 情绪图表组件：展示情绪趋势和分布 -->
  <div class="emotion-chart">
    <div class="emotion-chart__header">
      <h4>{{ title }}</h4>
      <div class="emotion-chart__controls">
        <el-radio-group v-model="chartType" size="small">
          <el-radio-button value="trend">趋势</el-radio-button>
          <el-radio-button value="distribution">分布</el-radio-button>
        </el-radio-group>
        <el-select v-model="timeRange" size="small" style="width: 120px" @change="fetchData">
          <el-option label="近7天" value="7d" />
          <el-option label="近30天" value="30d" />
          <el-option label="近90天" value="90d" />
        </el-select>
      </div>
    </div>

    <!-- 图表容器 -->
    <div ref="chartRef" class="emotion-chart__container" v-loading="loading"></div>
  </div>
</template>

<script setup>
/**
 * EmotionChart - 情绪图表组件
 * 使用 ECharts 展示情绪趋势和分布
 */
import { ref, watch, onMounted, onUnmounted, nextTick } from 'vue'
import * as echarts from 'echarts'
import { EMOTION_LABELS, EMOTION_COLORS } from '@/utils/constants'
import { getEmotionTrend } from '@/api/emotion'
import dayjs from 'dayjs'

const props = defineProps({
  // 图表标题
  title: {
    type: String,
    default: '情绪趋势'
  },
  // 员工 ID（可选，不传则显示全部）
  employeeId: {
    type: String,
    default: ''
  },
  // 图表高度
  height: {
    type: String,
    default: '300px'
  }
})

// 图表类型：趋势 / 分布
const chartType = ref('trend')
// 时间范围
const timeRange = ref('7d')
// 加载状态
const loading = ref(false)
// 图表实例
const chartRef = ref(null)
let chartInstance = null

/**
 * 初始化 ECharts 实例
 */
function initChart() {
  if (chartRef.value) {
    chartInstance = echarts.init(chartRef.value)
  }
}

/**
 * 获取情绪数据
 */
async function fetchData() {
  loading.value = true
  try {
    const res = await getEmotionTrend(props.employeeId, { days: timeRange.value })
    const trendData = res.data || []

    if (chartType.value === 'trend') {
      renderTrendChart(trendData)
    } else {
      renderDistributionChart(trendData)
    }
  } catch (error) {
    console.error('获取情绪数据失败:', error)
    // API 失败时渲染空图表
    if (chartType.value === 'trend') {
      renderTrendChart([])
    } else {
      renderDistributionChart([])
    }
  } finally {
    loading.value = false
  }
}

/**
 * 渲染趋势图
 */
function renderTrendChart(trendData = []) {
  if (!chartInstance) return

  const dates = trendData.map(d => d.date || d.recorded_at?.slice(5, 10) || '')
  const happyData = trendData.map(d => d.happy || d.happy_count || 0)
  const calmData = trendData.map(d => d.calm || d.calm_count || 0)
  const anxiousData = trendData.map(d => d.anxious || d.anxious_count || 0)

  const option = {
    tooltip: {
      trigger: 'axis',
      axisPointer: { type: 'cross' }
    },
    legend: {
      data: ['开心', '平静', '焦虑'],
      bottom: 0
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '12%',
      top: '8%',
      containLabel: true
    },
    xAxis: {
      type: 'category',
      data: dates,
      boundaryGap: false
    },
    yAxis: {
      type: 'value',
      name: '次数',
      minInterval: 1
    },
    series: [
      {
        name: '开心',
        type: 'line',
        smooth: true,
        data: happyData,
        itemStyle: { color: EMOTION_COLORS.happy },
        areaStyle: { color: 'rgba(103, 194, 58, 0.1)' }
      },
      {
        name: '平静',
        type: 'line',
        smooth: true,
        data: calmData,
        itemStyle: { color: EMOTION_COLORS.calm },
        areaStyle: { color: 'rgba(64, 158, 255, 0.1)' }
      },
      {
        name: '焦虑',
        type: 'line',
        smooth: true,
        data: anxiousData,
        itemStyle: { color: EMOTION_COLORS.anxious },
        areaStyle: { color: 'rgba(230, 162, 60, 0.1)' }
      }
    ]
  }

  chartInstance.setOption(option, true)
}

/**
 * 渲染分布饼图
 */
function renderDistributionChart(trendData = []) {
  if (!chartInstance) return

  // 从趋势数据中汇总各情绪出现次数
  const emotionCounts = {}
  for (const d of trendData) {
    for (const key of Object.keys(EMOTION_LABELS)) {
      if (d[key] || d[key + '_count']) {
        emotionCounts[key] = (emotionCounts[key] || 0) + (d[key] || d[key + '_count'] || 0)
      }
    }
  }

  const pieData = Object.keys(EMOTION_LABELS).map(key => ({
    name: EMOTION_LABELS[key],
    value: emotionCounts[key] || 0,
    itemStyle: { color: EMOTION_COLORS[key] }
  }))

  const option = {
    tooltip: {
      trigger: 'item',
      formatter: '{b}: {c}次 ({d}%)'
    },
    legend: {
      orient: 'vertical',
      right: '5%',
      top: 'center'
    },
    series: [
      {
        type: 'pie',
        radius: ['40%', '70%'],
        center: ['35%', '50%'],
        avoidLabelOverlap: false,
        label: { show: false },
        emphasis: {
          label: { show: true, fontSize: 14, fontWeight: 'bold' }
        },
        data: pieData
      }
    ]
  }

  chartInstance.setOption(option, true)
}

// 监听图表类型切换
watch(chartType, () => {
  fetchData()
})

// 监听窗口大小变化
const handleResize = () => {
  chartInstance?.resize()
}

onMounted(() => {
  nextTick(() => {
    initChart()
    fetchData()
  })
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
  chartInstance?.dispose()
  chartInstance = null
})
</script>

<style scoped>
.emotion-chart {
  background: #fff;
  border-radius: 8px;
  padding: 16px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
}

.emotion-chart__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
  flex-wrap: wrap;
  gap: 8px;
}

.emotion-chart__header h4 {
  margin: 0;
  font-size: 15px;
  color: #303133;
}

.emotion-chart__controls {
  display: flex;
  align-items: center;
  gap: 8px;
}

.emotion-chart__container {
  width: 100%;
  height: v-bind(height);
  min-height: 250px;
}
</style>
