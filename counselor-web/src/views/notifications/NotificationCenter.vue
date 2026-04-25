<template>
  <!-- 通知中心页面 -->
  <div class="notification-page page-container">
    <PageHeader title="通知中心">
      <template #actions>
        <el-button @click="handleMarkAllRead" :disabled="!hasUnread">全部已读</el-button>
        <el-button type="primary" :icon="Plus" @click="showSendDialog">发送通知</el-button>
      </template>
    </PageHeader>

    <div class="card-container">
      <!-- 筛选 -->
      <div class="search-bar">
        <el-radio-group v-model="readFilter" size="small" @change="fetchData">
          <el-radio-button value="">全部</el-radio-button>
          <el-radio-button value="unread">未读</el-radio-button>
          <el-radio-button value="read">已读</el-radio-button>
        </el-radio-group>
        <el-select v-model="typeFilter" placeholder="类型" clearable size="small" style="width: 140px" @change="fetchData">
          <el-option v-for="(label, key) in NOTIFICATION_TYPE_LABELS" :key="key" :label="label" :value="key" />
        </el-select>
      </div>

      <!-- 通知列表 -->
      <div class="notification-list" v-loading="loading">
        <div
          v-for="item in notifications"
          :key="item.id"
          class="notification-item"
          :class="{ 'notification-item--unread': !item.read }"
          @click="handleRead(item)"
        >
          <div class="notification-icon" :style="{ backgroundColor: getTypeColor(item.type) + '15', color: getTypeColor(item.type) }">
            <el-icon :size="18">
              <Bell v-if="item.type === 'system'" />
              <List v-else-if="item.type === 'task'" />
              <Sunny v-else-if="item.type === 'emotion'" />
              <Microphone v-else-if="item.type === 'voice_cheer'" />
              <VideoCamera v-else />
            </el-icon>
          </div>
          <div class="notification-content">
            <div class="notification-header">
              <span class="notification-title">{{ item.title }}</span>
              <el-tag :type="getTypeTagType(item.type)" size="small">{{ NOTIFICATION_TYPE_LABELS[item.type] || item.type }}</el-tag>
            </div>
            <p class="notification-body">{{ item.content }}</p>
            <div class="notification-footer">
              <span class="notification-time">{{ item.createdAt }}</span>
              <span v-if="!item.read" class="unread-dot"></span>
            </div>
          </div>
          <el-button class="notification-delete" size="small" text type="danger" :icon="Delete" @click.stop="handleDelete(item)" />
        </div>
        <el-empty v-if="notifications.length === 0" description="暂无通知" :image-size="80" />
      </div>

      <!-- 分页 -->
      <div class="pagination-wrapper">
        <el-pagination
          v-model:current-page="page"
          v-model:page-size="pageSize"
          :total="total"
          layout="total, prev, pager, next"
          @current-change="fetchData"
        />
      </div>
    </div>

    <!-- 发送通知对话框 -->
    <el-dialog v-model="sendDialogVisible" title="发送通知" width="560px" destroy-on-close>
      <el-form ref="sendFormRef" :model="sendForm" :rules="sendRules" label-width="100px">
        <el-form-item label="通知类型" prop="type">
          <el-select v-model="sendForm.type" placeholder="选择类型">
            <el-option v-for="(label, key) in NOTIFICATION_TYPE_LABELS" :key="key" :label="label" :value="key" />
          </el-select>
        </el-form-item>
        <el-form-item label="标题" prop="title">
          <el-input v-model="sendForm.title" placeholder="通知标题" />
        </el-form-item>
        <el-form-item label="内容" prop="content">
          <el-input v-model="sendForm.content" type="textarea" :rows="3" placeholder="通知内容" />
        </el-form-item>
        <el-form-item label="目标员工" prop="targetEmployeeIds">
          <el-select v-model="sendForm.targetEmployeeIds" multiple placeholder="选择员工（不选则发送给全部）" style="width: 100%">
            <el-option v-for="emp in employeeOptions" :key="emp.id" :label="emp.name" :value="emp.id" />
          </el-select>
        </el-form-item>
        <!-- 语音鼓励特有字段 -->
        <el-form-item v-if="sendForm.type === 'voice_cheer'" label="语音">
          <AudioRecorder v-model="sendForm.audioUrl" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="sendDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="sendLoading" @click="handleSend">发送</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
/**
 * NotificationCenter - 通知中心页面
 * 通知列表、发送通知（含语音鼓励）
 */
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Delete, Bell, List, Sunny, Microphone, VideoCamera } from '@element-plus/icons-vue'
import PageHeader from '@/components/PageHeader.vue'
import AudioRecorder from '@/components/AudioRecorder.vue'
import { useNotificationStore } from '@/stores/notification'
import { sendNotification, sendVoiceCheer, deleteNotification as deleteNotifApi } from '@/api/notification'
import { NOTIFICATION_TYPE_LABELS } from '@/utils/constants'
import { getEmployeeList } from '@/api/user'

const notificationStore = useNotificationStore()
const loading = ref(false)
const readFilter = ref('')
const typeFilter = ref('')
const page = ref(1)
const pageSize = ref(20)
const total = ref(0)
const notifications = computed(() => notificationStore.notifications)
const hasUnread = computed(() => notificationStore.hasUnread)
const employeeOptions = ref([])

// 发送对话框
const sendDialogVisible = ref(false)
const sendLoading = ref(false)
const sendFormRef = ref(null)
const sendForm = reactive({
  type: 'system',
  title: '',
  content: '',
  targetEmployeeIds: [],
  audioUrl: ''
})
const sendRules = {
  type: [{ required: true, message: '请选择类型', trigger: 'change' }],
  title: [{ required: true, message: '请输入标题', trigger: 'blur' }],
  content: [{ required: true, message: '请输入内容', trigger: 'blur' }]
}

function getTypeColor(type) {
  const map = { system: '#909399', task: '#409EFF', emotion: '#F56C6C', voice_cheer: '#67C23A', remote_assist: '#E6A23C' }
  return map[type] || '#909399'
}

function getTypeTagType(type) {
  const map = { system: 'info', task: '', emotion: 'danger', voice_cheer: 'success', remote_assist: 'warning' }
  return map[type] || 'info'
}

async function fetchData() {
  loading.value = true
  try {
    await notificationStore.fetchNotifications({
      page: page.value,
      pageSize: pageSize.value,
      type: typeFilter.value,
      read: readFilter.value
    })
    total.value = notificationStore.total
  } finally {
    loading.value = false
  }
}

async function handleRead(item) {
  if (!item.read) {
    await notificationStore.markRead(item.id)
  }
}

async function handleMarkAllRead() {
  await notificationStore.markAllRead()
  ElMessage.success('已全部标记为已读')
  fetchData()
}

async function handleDelete(item) {
  try {
    await ElMessageBox.confirm('确定删除该通知吗？', '确认', { type: 'warning' })
    await notificationStore.deleteNotification(item.id)
    ElMessage.success('删除成功')
  } catch (error) { if (error !== 'cancel') console.error(error) }
}

function showSendDialog() {
  Object.assign(sendForm, { type: 'system', title: '', content: '', targetEmployeeIds: [], audioUrl: '' })
  sendDialogVisible.value = true
}

async function handleSend() {
  try { await sendFormRef.value.validate() } catch { return }
  sendLoading.value = true
  try {
    if (sendForm.type === 'voice_cheer') {
      await sendVoiceCheer({
        employeeId: sendForm.targetEmployeeIds[0],
        audioUrl: sendForm.audioUrl,
        text: sendForm.content
      })
    } else {
      await sendNotification(sendForm)
    }
    ElMessage.success('通知发送成功')
    sendDialogVisible.value = false
    fetchData()
  } catch (error) {
    console.error('发送失败:', error)
  } finally {
    sendLoading.value = false
  }
}

onMounted(() => {
  fetchData()
  getEmployeeList({ page: 1, pageSize: 100 }).then(res => {
    employeeOptions.value = res.data?.list || []
  }).catch(() => {})
})
</script>

<style scoped>
.notification-list {
  max-height: 600px;
  overflow-y: auto;
}

.notification-item {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding: 16px;
  border-bottom: 1px solid #f0f0f0;
  cursor: pointer;
  transition: background 0.2s;
}

.notification-item:hover { background: #fafafa; }
.notification-item--unread { background: #f0f9ff; }
.notification-item--unread:hover { background: #e6f4ff; }

.notification-icon {
  width: 40px;
  height: 40px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.notification-content { flex: 1; min-width: 0; }

.notification-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 4px;
}

.notification-title {
  font-size: 14px;
  font-weight: 500;
  color: #303133;
}

.notification-body {
  font-size: 13px;
  color: #606266;
  margin: 0 0 4px;
  line-height: 1.5;
}

.notification-footer {
  display: flex;
  align-items: center;
  gap: 8px;
}

.notification-time {
  font-size: 12px;
  color: #C0C4CC;
}

.unread-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #409EFF;
}

.notification-delete {
  flex-shrink: 0;
  opacity: 0;
  transition: opacity 0.2s;
}

.notification-item:hover .notification-delete { opacity: 1; }

.pagination-wrapper {
  display: flex;
  justify-content: flex-end;
  margin-top: 16px;
}
</style>
