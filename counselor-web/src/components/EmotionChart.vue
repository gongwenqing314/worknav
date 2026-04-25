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
 * 获取模拟数据（实际项目中替换为 API 调用）
 */
async function fetchData() {
  loading.value = true
  try {
    // 模拟数据 - 实际使用时替换为 API 调用
    // const res = await getEmotionTrend(props.employeeId, { timeRange: timeRange.value })
    await new Promise(resolve => setTimeout(resolve, 500))

    if (chartType.value === 'trend') {
      renderTrendChart()
    } else {
      renderDistributionChart()
    }
  } finally {
    loading.value = false
  }
}

/**
 * 渲染趋势图
 */
function renderTrendChart() {
  if (!chartInstance) return

  // 生成模拟日期数据
  const days = parseInt(timeRange.value)
  const dates = []
  const happyData = []
  const calmData = []
  const anxiousData = []

  for (let i = days - 1; i >= 0; i--) {
    const date = dayjs().subtract(i, 'day').format('MM-DD')
    dates.push(date)
    happyData.push(Math.floor(Math.random() * 5) + 2)
    calmData.push(Math.floor(Math.random() * 4) + 3)
    anxiousData.push(Math.floor(Math.random() * 3))
  }

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
function renderDistributionChart() {
  if (!chartInstance) return

  const emotionKeys = Object.keys(EMOTION_LABELS)
  const pieData = emotionKeys.map(key => ({
    name: EMOTION_LABELS[key],
    value: Math.floor(Math.random() * 20) + 5,
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
