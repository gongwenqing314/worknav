<template>
  <!-- 步骤编辑器：支持拖拽排序、图片/视频上传、语音录制、关键步骤标记 -->
  <div class="step-editor">
    <div class="step-editor__header">
      <span class="step-editor__label">任务步骤</span>
      <el-button type="primary" size="small" :icon="Plus" @click="addStep">
        添加步骤
      </el-button>
    </div>

    <!-- 拖拽排序列表 -->
    <draggable
      :list="steps"
      item-key="id"
      handle=".step-handle"
      animation="200"
      ghost-class="step-ghost"
      @end="onDragEnd"
    >
      <template #item="{ element, index }">
        <div class="step-item" :class="{ 'step-item--key': element.isKey }">
          <!-- 拖拽手柄 + 序号 -->
          <div class="step-item__left">
            <el-icon class="step-handle" :size="18"><Rank /></el-icon>
            <span class="step-item__index">{{ index + 1 }}</span>
            <el-tag v-if="element.isKey" type="danger" size="small" effect="dark">关键</el-tag>
          </div>

          <!-- 步骤内容 -->
          <div class="step-item__content">
            <el-input
              v-model="element.title"
              placeholder="步骤标题"
              size="default"
              class="step-title-input"
            />
            <el-input
              v-model="element.description"
              type="textarea"
              :rows="2"
              placeholder="步骤描述（可选）"
              size="default"
            />

            <!-- 媒体资源区域 -->
            <div class="step-media">
              <!-- 图片上传 -->
              <div class="media-section">
                <span class="media-label">图片：</span>
                <ImageUpload
                  v-model="element.imageUrl"
                  :max-size="10 * 1024 * 1024"
                  accept=".jpg,.jpeg,.png,.gif,.webp"
                />
              </div>

              <!-- 视频上传 -->
              <div class="media-section">
                <span class="media-label">视频：</span>
                <el-upload
                  :action="uploadUrl"
                  :headers="uploadHeaders"
                  :show-file-list="false"
                  :before-upload="beforeVideoUpload"
                  :on-success="(res) => onVideoUploadSuccess(res, element)"
                  accept=".mp4,.mov,.avi"
                >
                  <el-button size="small" :icon="VideoCamera">上传视频</el-button>
                </el-upload>
                <span v-if="element.videoUrl" class="media-file-name">已上传</span>
              </div>

              <!-- 语音录制 -->
              <div class="media-section">
                <span class="media-label">语音：</span>
                <AudioRecorder
                  v-model="element.audioUrl"
                  :max-duration="60"
                />
              </div>
            </div>
          </div>

          <!-- 操作按钮 -->
          <div class="step-item__actions">
            <!-- 关键步骤标记 -->
            <el-tooltip :content="element.isKey ? '取消关键步骤' : '标记为关键步骤'">
              <el-button
                :type="element.isKey ? 'danger' : 'default'"
                size="small"
                :icon="Star"
                circle
                @click="toggleKeyStep(index)"
              />
            </el-tooltip>
            <!-- 删除步骤 -->
            <el-button
              type="danger"
              size="small"
              :icon="Delete"
              circle
              plain
              @click="removeStep(index)"
              :disabled="steps.length <= 1"
            />
          </div>
        </div>
      </template>
    </draggable>
  </div>
</template>

<script setup>
/**
 * StepEditor - 步骤编辑器组件
 * 支持拖拽排序、图片/视频上传、语音录制、关键步骤标记
 */
import { ref, watch } from 'vue'
import draggable from 'vuedraggable'
import { Plus, Delete, Star, Rank, VideoCamera } from '@element-plus/icons-vue'
import ImageUpload from './ImageUpload.vue'
import AudioRecorder from './AudioRecorder.vue'
import { generateId } from '@/utils/helpers'
import { UPLOAD_LIMITS } from '@/utils/constants'

const props = defineProps({
  // 步骤列表（v-model）
  modelValue: {
    type: Array,
    default: () => []
  }
})

const emit = defineEmits(['update:modelValue', 'change'])

// 上传地址
const uploadUrl = import.meta.env.VITE_UPLOAD_URL || '/api/upload'

// 上传请求头（携带 Token）
const uploadHeaders = {
  Authorization: `Bearer ${localStorage.getItem('token') || ''}`
}

// 内部步骤数据
const steps = ref([])

// 初始化步骤数据（仅在首次或外部传入新数组时同步）
let isInitialized = false
watch(
  () => props.modelValue,
  (val) => {
    if (!isInitialized || val !== steps.value) {
      if (val && val.length > 0) {
        steps.value = val.map(s => ({ ...s, id: s.id || generateId() }))
      } else if (!isInitialized) {
        steps.value = [createEmptyStep()]
      }
      isInitialized = true
    }
  },
  { immediate: true }
)

// 通知父组件的函数
function notifyChange() {
  emit('update:modelValue', steps.value)
  emit('change', steps.value)
}

/**
 * 创建空步骤
 */
function createEmptyStep() {
  return {
    id: generateId(),
    title: '',
    description: '',
    imageUrl: '',
    videoUrl: '',
    audioUrl: '',
    isKey: false,
    sortOrder: 0
  }
}

/**
 * 添加步骤
 */
function addStep() {
  steps.value.push(createEmptyStep())
  notifyChange()
}

/**
 * 删除步骤
 */
function removeStep(index) {
  if (steps.value.length <= 1) return
  steps.value.splice(index, 1)
  notifyChange()
}

/**
 * 切换关键步骤标记
 */
function toggleKeyStep(index) {
  steps.value[index].isKey = !steps.value[index].isKey
  notifyChange()
}

/**
 * 拖拽结束回调
 */
function onDragEnd() {
  steps.value.forEach((step, index) => {
    step.sortOrder = index
  })
  notifyChange()
}

/**
 * 视频上传前校验
 */
function beforeVideoUpload(file) {
  const isVideo = file.type.startsWith('video/')
  const isLt50M = file.size <= UPLOAD_LIMITS.VIDEO_MAX_SIZE
  if (!isVideo) {
    ElMessage.error('只能上传视频文件')
    return false
  }
  if (!isLt50M) {
    ElMessage.error('视频大小不能超过 50MB')
    return false
  }
  return true
}

/**
 * 视频上传成功
 */
function onVideoUploadSuccess(response, element) {
  if (response?.data?.url) {
    element.videoUrl = response.data.url
  }
}
</script>

<style scoped>
.step-editor {
  border: 1px solid var(--color-border-light);
  border-radius: 8px;
  padding: 16px;
  background: #fafafa;
}

.step-editor__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16px;
}

.step-editor__label {
  font-size: 15px;
  font-weight: 600;
  color: #303133;
}

/* ===== 步骤项 ===== */
.step-item {
  background: #fff;
  border: 1px solid var(--color-border-light);
  border-radius: 8px;
  padding: 16px;
  margin-bottom: 12px;
  display: flex;
  gap: 12px;
  transition: box-shadow 0.2s;
}

.step-item:hover {
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.step-item--key {
  border-left: 3px solid #F56C6C;
}

.step-ghost {
  opacity: 0.5;
  background: #ecf5ff;
}

.step-item__left {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  padding-top: 4px;
}

.step-handle {
  cursor: grab;
  color: #C0C4CC;
  transition: color 0.2s;
}

.step-handle:hover {
  color: #409EFF;
}

.step-handle:active {
  cursor: grabbing;
}

.step-item__index {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  background: #409EFF;
  color: #fff;
  font-size: 12px;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
}

.step-item__content {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.step-title-input {
  font-weight: 500;
}

/* ===== 媒体资源 ===== */
.step-media {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  padding-top: 8px;
  border-top: 1px dashed var(--color-border-light);
}

.media-section {
  display: flex;
  align-items: center;
  gap: 6px;
}

.media-label {
  font-size: 12px;
  color: #909399;
  white-space: nowrap;
}

.media-file-name {
  font-size: 12px;
  color: #67C23A;
}

/* ===== 操作按钮 ===== */
.step-item__actions {
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding-top: 4px;
}

@media screen and (max-width: 768px) {
  .step-item {
    flex-direction: column;
  }

  .step-item__left {
    flex-direction: row;
  }

  .step-item__actions {
    flex-direction: row;
    justify-content: flex-end;
  }

  .step-media {
    flex-direction: column;
  }
}
</style>
