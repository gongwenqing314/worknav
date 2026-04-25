<template>
  <!-- 统计卡片：展示关键指标数据 -->
  <div class="stat-card" :style="{ borderTopColor: color }">
    <div class="stat-card__icon" :style="{ backgroundColor: color + '15', color: color }">
      <el-icon :size="28"><component :is="icon" /></el-icon>
    </div>
    <div class="stat-card__content">
      <div class="stat-card__value">{{ displayValue }}</div>
      <div class="stat-card__label">{{ title }}</div>
    </div>
    <div v-if="trend !== undefined" class="stat-card__trend" :class="trendClass">
      <el-icon :size="14">
        <Top v-if="trend > 0" />
        <Bottom v-else-if="trend < 0" />
        <Minus v-else />
      </el-icon>
      <span>{{ Math.abs(trend) }}%</span>
    </div>
  </div>
</template>

<script setup>
/**
 * StatCard - 统计卡片组件
 * 用于仪表盘展示关键指标
 */
import { computed } from 'vue'

const props = defineProps({
  // 标题
  title: {
    type: String,
    required: true
  },
  // 数值
  value: {
    type: [Number, String],
    default: 0
  },
  // 图标名称
  icon: {
    type: String,
    default: 'DataLine'
  },
  // 主题色
  color: {
    type: String,
    default: '#409EFF'
  },
  // 趋势百分比（正数上升，负数下降）
  trend: {
    type: Number,
    default: undefined
  },
  // 是否使用千分位格式
  useGrouping: {
    type: Boolean,
    default: false
  }
})

// 格式化显示值
const displayValue = computed(() => {
  const num = Number(props.value)
  if (isNaN(num)) return props.value
  if (props.useGrouping) {
    return num.toLocaleString('zh-CN')
  }
  return props.value
})

// 趋势样式类
const trendClass = computed(() => {
  if (props.trend > 0) return 'trend-up'
  if (props.trend < 0) return 'trend-down'
  return 'trend-flat'
})
</script>

<style scoped>
.stat-card {
  background: #fff;
  border-radius: 8px;
  padding: 20px;
  display: flex;
  align-items: center;
  gap: 16px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
  border-top: 3px solid;
  transition: transform 0.2s, box-shadow 0.2s;
  position: relative;
}

.stat-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.stat-card__icon {
  width: 56px;
  height: 56px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.stat-card__content {
  flex: 1;
  min-width: 0;
}

.stat-card__value {
  font-size: 28px;
  font-weight: 700;
  color: #303133;
  line-height: 1.2;
}

.stat-card__label {
  font-size: 13px;
  color: #909399;
  margin-top: 4px;
}

.stat-card__trend {
  position: absolute;
  top: 12px;
  right: 16px;
  display: flex;
  align-items: center;
  gap: 2px;
  font-size: 12px;
  font-weight: 500;
}

.trend-up {
  color: #67C23A;
}

.trend-down {
  color: #F56C6C;
}

.trend-flat {
  color: #909399;
}

@media screen and (max-width: 768px) {
  .stat-card {
    padding: 16px;
  }

  .stat-card__value {
    font-size: 22px;
  }

  .stat-card__icon {
    width: 44px;
    height: 44px;
  }
}
</style>
