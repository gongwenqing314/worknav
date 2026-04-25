<template>
  <!-- 页面头部组件：标题 + 操作按钮 -->
  <div class="page-header">
    <div class="page-header__left">
      <!-- 返回按钮（可选） -->
      <el-button
        v-if="showBack"
        :icon="ArrowLeft"
        text
        @click="handleBack"
        class="back-btn"
      />
      <h2 class="page-header__title">{{ title }}</h2>
      <slot name="extra" />
    </div>
    <div class="page-header__right">
      <slot name="actions" />
    </div>
  </div>
</template>

<script setup>
/**
 * PageHeader - 页面头部组件
 * 提供统一的页面标题和操作按钮区域
 */
import { useRouter } from 'vue-router'
import { ArrowLeft } from '@element-plus/icons-vue'

const props = defineProps({
  // 页面标题
  title: {
    type: String,
    required: true
  },
  // 是否显示返回按钮
  showBack: {
    type: Boolean,
    default: false
  }
})

const router = useRouter()

/**
 * 返回上一页
 */
const handleBack = () => {
  router.back()
}
</script>

<style scoped>
.page-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 24px;
  background: #fff;
  border-bottom: 1px solid var(--color-border-light);
  flex-wrap: wrap;
  gap: 12px;
}

.page-header__left {
  display: flex;
  align-items: center;
  gap: 8px;
}

.page-header__title {
  font-size: 18px;
  font-weight: 600;
  color: var(--color-text-primary);
  margin: 0;
}

.back-btn {
  margin-right: 4px;
}

.page-header__right {
  display: flex;
  align-items: center;
  gap: 8px;
}

@media screen and (max-width: 768px) {
  .page-header {
    padding: 12px 16px;
  }

  .page-header__title {
    font-size: 16px;
  }
}
</style>
