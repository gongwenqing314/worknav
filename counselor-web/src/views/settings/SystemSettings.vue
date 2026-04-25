<template>
  <!-- 系统设置页面（仅管理员） -->
  <div class="system-settings-page page-container">
    <PageHeader title="系统设置" />

    <div class="settings-layout">
      <!-- 基本设置 -->
      <div class="card-container settings-section">
        <h3 class="section-title">基本设置</h3>
        <el-form :model="settings" label-width="140px">
          <el-form-item label="系统名称">
            <el-input v-model="settings.systemName" />
          </el-form-item>
          <el-form-item label="机构名称">
            <el-input v-model="settings.orgName" />
          </el-form-item>
          <el-form-item label="默认语言">
            <el-select v-model="settings.language">
              <el-option label="简体中文" value="zh-CN" />
              <el-option label="English" value="en-US" />
            </el-select>
          </el-form-item>
          <el-form-item label="数据保留天数">
            <el-input-number v-model="settings.dataRetentionDays" :min="30" :max="365" />
            <span class="form-tip">天</span>
          </el-form-item>
        </el-form>
      </div>

      <!-- 通知设置 -->
      <div class="card-container settings-section">
        <h3 class="section-title">通知设置</h3>
        <el-form :model="settings" label-width="140px">
          <el-form-item label="情绪预警通知">
            <el-switch v-model="settings.emotionAlertNotify" />
          </el-form-item>
          <el-form-item label="远程协助通知">
            <el-switch v-model="settings.assistNotify" />
          </el-form-item>
          <el-form-item label="任务完成通知">
            <el-switch v-model="settings.taskCompleteNotify" />
          </el-form-item>
          <el-form-item label="每日报告推送">
            <el-switch v-model="settings.dailyReport" />
          </el-form-item>
          <el-form-item label="推送时间">
            <el-time-picker v-model="settings.pushTime" placeholder="选择时间" />
          </el-form-item>
        </el-form>
      </div>

      <!-- 安全设置 -->
      <div class="card-container settings-section">
        <h3 class="section-title">安全设置</h3>
        <el-form :model="settings" label-width="140px">
          <el-form-item label="密码最小长度">
            <el-input-number v-model="settings.minPasswordLength" :min="6" :max="20" />
          </el-form-item>
          <el-form-item label="登录失败锁定">
            <el-input-number v-model="settings.maxLoginAttempts" :min="3" :max="10" />
            <span class="form-tip">次</span>
          </el-form-item>
          <el-form-item label="会话超时">
            <el-input-number v-model="settings.sessionTimeout" :min="30" :max="480" />
            <span class="form-tip">分钟</span>
          </el-form-item>
        </el-form>
      </div>
    </div>

    <div class="save-bar">
      <el-button type="primary" :loading="saving" @click="handleSave">保存设置</el-button>
    </div>
  </div>
</template>

<script setup>
/**
 * SystemSettings - 系统设置页面（仅管理员可访问）
 */
import { ref, reactive } from 'vue'
import { ElMessage } from 'element-plus'
import PageHeader from '@/components/PageHeader.vue'

const saving = ref(false)
const settings = reactive({
  systemName: '工作导航',
  orgName: '',
  language: 'zh-CN',
  dataRetentionDays: 90,
  emotionAlertNotify: true,
  assistNotify: true,
  taskCompleteNotify: false,
  dailyReport: true,
  pushTime: '18:00',
  minPasswordLength: 6,
  maxLoginAttempts: 5,
  sessionTimeout: 120
})

async function handleSave() {
  saving.value = true
  try {
    // 模拟保存
    await new Promise(resolve => setTimeout(resolve, 800))
    ElMessage.success('设置已保存')
  } finally {
    saving.value = false
  }
}
</script>

<style scoped>
.section-title {
  margin: 0 0 16px;
  font-size: 15px;
  font-weight: 600;
  color: #303133;
}

.settings-layout {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
  gap: 16px;
}

.form-tip {
  font-size: 12px;
  color: #909399;
  margin-left: 8px;
}

.save-bar {
  margin-top: 24px;
  text-align: center;
}

@media screen and (max-width: 768px) {
  .settings-layout {
    grid-template-columns: 1fr;
  }
}
</style>
