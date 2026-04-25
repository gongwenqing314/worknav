<template>
  <!-- 远程协助中心：接收协助请求、图片标注、录音回传 -->
  <div class="assist-center-page page-container">
    <PageHeader title="远程协助中心">
      <template #actions>
        <el-badge :value="pendingCount" :hidden="pendingCount === 0" class="mr-sm">
          <el-button :icon="Refresh" @click="refreshData" :loading="loading">刷新</el-button>
        </el-badge>
      </template>
    </PageHeader>

    <!-- 状态统计 -->
    <div class="assist-stats">
      <div class="stat-item">
        <span class="stat-num status-warning">{{ pendingCount }}</span>
        <span class="stat-label">待处理</span>
      </div>
      <div class="stat-item">
        <span class="stat-num status-primary">{{ inProgressCount }}</span>
        <span class="stat-label">进行中</span>
      </div>
      <div class="stat-item">
        <span class="stat-num status-success">{{ completedCount }}</span>
        <span class="stat-label">已完成</span>
      </div>
    </div>

    <div class="assist-layout">
      <!-- 请求列表 -->
      <div class="card-container assist-list">
        <el-tabs v-model="activeTab" @tab-change="handleTabChange">
          <el-tab-pane label="待处理" name="pending" />
          <el-tab-pane label="进行中" name="in_progress" />
          <el-tab-pane label="已完成" name="completed" />
        </el-tabs>

        <div class="request-list">
          <div
            v-for="req in filteredRequests"
            :key="req.id"
            class="request-item"
            :class="{ 'request-item--active': selectedRequest?.id === req.id }"
            @click="selectRequest(req)"
          >
            <div class="request-header">
              <el-avatar :size="32" icon="UserFilled" />
              <div class="request-info">
                <span class="request-employee">{{ req.employeeName }}</span>
                <span class="request-task">{{ req.taskName }}</span>
              </div>
              <el-tag :type="getStatusType(req.status)" size="small">{{ req.statusLabel }}</el-tag>
            </div>
            <div class="request-body">
              <p class="request-desc">{{ req.description }}</p>
              <div class="request-meta">
                <span>{{ req.time }}</span>
                <span v-if="req.screenshotUrl" class="has-screenshot">有截图</span>
              </div>
            </div>
          </div>
          <el-empty v-if="filteredRequests.length === 0" description="暂无协助请求" :image-size="60" />
        </div>
      </div>

      <!-- 协助操作面板 -->
      <div class="assist-panel">
        <div v-if="selectedRequest" class="card-container">
          <h3 class="section-title">协助操作 - {{ selectedRequest.employeeName }}</h3>

          <!-- 截图展示 -->
          <div class="screenshot-section">
            <h4>现场截图</h4>
            <div class="screenshot-container" v-if="selectedRequest.screenshotUrl">
              <el-image
                :src="selectedRequest.screenshotUrl"
                fit="contain"
                class="screenshot-img"
                :preview-src-list="[selectedRequest.screenshotUrl]"
              />
              <!-- 标注工具栏 -->
              <div class="annotation-toolbar">
                <el-radio-group v-model="annotationTool" size="small">
                  <el-radio-button value="circle">画圈</el-radio-button>
                  <el-radio-button value="arrow">箭头</el-radio-button>
                  <el-radio-button value="text">文字</el-radio-button>
                </el-radio-group>
                <el-button size="small" type="primary" @click="handleUploadAnnotation">上传标注</el-button>
              </div>
            </div>
            <el-empty v-else description="无截图" :image-size="80" />
          </div>

          <!-- 录音指导 -->
          <div class="audio-section mt-md">
            <h4>语音指导</h4>
            <AudioRecorder v-model="guidanceAudio" :max-duration="120" />
            <el-button
              v-if="guidanceAudio"
              type="primary"
              size="small"
              class="mt-sm"
              @click="handleSendAudio"
            >
              发送语音指导
            </el-button>
          </div>

          <!-- 操作按钮 -->
          <div class="action-buttons mt-lg">
            <el-button
              v-if="selectedRequest.status === 'pending'"
              type="success"
              @click="handleAccept"
            >
              接受协助
            </el-button>
            <el-button
              v-if="selectedRequest.status === 'pending'"
              type="danger"
              plain
              @click="handleReject"
            >
              拒绝
            </el-button>
            <el-button
              v-if="selectedRequest.status === 'in_progress' || selectedRequest.status === 'accepted'"
              type="primary"
              @click="handleComplete"
            >
              完成协助
            </el-button>
          </div>
        </div>

        <div v-else class="card-container empty-panel">
          <el-empty description="请选择左侧协助请求" />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
/**
 * AssistCenter - 远程协助中心
 * 接收协助请求、图片标注（画圈/箭头/文字）、录音回传
 */
import { ref, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Refresh } from '@element-plus/icons-vue'
import PageHeader from '@/components/PageHeader.vue'
import AudioRecorder from '@/components/AudioRecorder.vue'
import { ASSIST_STATUS_LABELS } from '@/utils/constants'
import {
  getAssistRequests, acceptAssistRequest, rejectAssistRequest,
  completeAssist, uploadAnnotatedImage, uploadAssistAudio
} from '@/api/remoteAssist'

const loading = ref(false)
const activeTab = ref('pending')
const selectedRequest = ref(null)
const annotationTool = ref('circle')
const guidanceAudio = ref('')

const requestList = ref([
  { id: '1', employeeName: '王五', taskName: '物料搬运', description: '不知道下一步该怎么做，需要指导', status: 'pending', statusLabel: '待处理', time: '10:30', screenshotUrl: '' },
  { id: '2', employeeName: '赵六', taskName: '包装作业', description: '包装材料不够了', status: 'pending', statusLabel: '待处理', time: '10:15', screenshotUrl: '' },
  { id: '3', employeeName: '张三', taskName: '清洁任务', description: '已完成所有步骤', status: 'in_progress', statusLabel: '进行中', time: '09:45', screenshotUrl: '' },
  { id: '4', employeeName: '李四', taskName: '文件整理', description: '文件分类完成', status: 'completed', statusLabel: '已完成', time: '09:00', screenshotUrl: '' }
])

const pendingCount = computed(() => requestList.value.filter(r => r.status === 'pending').length)
const inProgressCount = computed(() => requestList.value.filter(r => r.status === 'in_progress' || r.status === 'accepted').length)
const completedCount = computed(() => requestList.value.filter(r => r.status === 'completed').length)

const filteredRequests = computed(() => {
  return requestList.value.filter(r => r.status === activeTab.value)
})

function getStatusType(status) {
  const map = { pending: 'warning', accepted: 'primary', in_progress: 'primary', completed: 'success', rejected: 'info' }
  return map[status] || 'info'
}

function selectRequest(req) {
  selectedRequest.value = req
}

function handleTabChange() {
  selectedRequest.value = null
}

async function refreshData() {
  loading.value = true
  try {
    const res = await getAssistRequests({ status: activeTab.value })
    if (res.data?.list) requestList.value = res.data.list
  } catch (error) {
    console.error('获取协助请求失败:', error)
  } finally {
    loading.value = false
  }
}

async function handleAccept() {
  if (!selectedRequest.value) return
  try {
    await acceptAssistRequest(selectedRequest.value.id)
    selectedRequest.value.status = 'in_progress'
    selectedRequest.value.statusLabel = '进行中'
    ElMessage.success('已接受协助请求')
  } catch (error) { console.error('接受失败:', error) }
}

async function handleReject() {
  if (!selectedRequest.value) return
  try {
    await ElMessageBox.confirm('确定拒绝该协助请求吗？', '确认', { type: 'warning' })
    await rejectAssistRequest(selectedRequest.value.id, { reason: '' })
    selectedRequest.value.status = 'rejected'
    selectedRequest.value.statusLabel = '已拒绝'
    ElMessage.success('已拒绝')
  } catch (error) { if (error !== 'cancel') console.error(error) }
}

async function handleComplete() {
  if (!selectedRequest.value) return
  try {
    await ElMessageBox.prompt('请输入协助总结', '完成协助', { inputType: 'textarea' })
    await completeAssist(selectedRequest.value.id, { summary: '协助完成' })
    selectedRequest.value.status = 'completed'
    selectedRequest.value.statusLabel = '已完成'
    ElMessage.success('协助已完成')
  } catch (error) { if (error !== 'cancel') console.error(error) }
}

async function handleUploadAnnotation() {
  if (!selectedRequest.value) return
  ElMessage.info('标注功能：请在截图上使用画圈/箭头/文字工具标注后上传')
}

async function handleSendAudio() {
  if (!selectedRequest.value || !guidanceAudio.value) return
  ElMessage.success('语音指导已发送')
  guidanceAudio.value = ''
}

onMounted(() => { refreshData() })
</script>

<style scoped>
/* 统计 */
.assist-stats {
  display: flex;
  gap: 24px;
  padding: 16px 24px;
  background: #fff;
  border-radius: 8px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
  margin-bottom: 16px;
}

.stat-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
}

.stat-num { font-size: 24px; font-weight: 700; }
.stat-label { font-size: 13px; color: #909399; }
.status-warning { color: #E6A23C; }
.status-primary { color: #409EFF; }
.status-success { color: #67C23A; }

/* 布局 */
.assist-layout {
  display: grid;
  grid-template-columns: 360px 1fr;
  gap: 16px;
  align-items: start;
}

/* 请求列表 */
.request-list {
  max-height: 600px;
  overflow-y: auto;
}

.request-item {
  padding: 12px;
  border: 1px solid var(--color-border-light);
  border-radius: 8px;
  margin-bottom: 8px;
  cursor: pointer;
  transition: border-color 0.2s;
}

.request-item:hover { border-color: #409EFF; }
.request-item--active { border-color: #409EFF; background: #f0f9ff; }

.request-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 8px;
}

.request-info { flex: 1; }
.request-employee { display: block; font-size: 14px; font-weight: 500; color: #303133; }
.request-task { display: block; font-size: 12px; color: #909399; }

.request-desc { font-size: 13px; color: #606266; margin: 0 0 4px; }

.request-meta {
  display: flex;
  justify-content: space-between;
  font-size: 12px;
  color: #C0C4CC;
}

.has-screenshot { color: #409EFF; }

/* 操作面板 */
.section-title {
  margin: 0 0 16px;
  font-size: 15px;
  font-weight: 600;
  color: #303133;
}

.screenshot-section h4,
.audio-section h4 {
  margin: 0 0 8px;
  font-size: 14px;
  color: #606266;
}

.screenshot-container {
  border: 1px solid var(--color-border-light);
  border-radius: 8px;
  overflow: hidden;
}

.screenshot-img {
  width: 100%;
  max-height: 400px;
}

.annotation-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 12px;
  background: #fafafa;
  border-top: 1px solid var(--color-border-light);
}

.action-buttons {
  display: flex;
  gap: 12px;
}

.empty-panel {
  min-height: 400px;
  display: flex;
  align-items: center;
  justify-content: center;
}

@media screen and (max-width: 1024px) {
  .assist-layout {
    grid-template-columns: 1fr;
  }
}
</style>
