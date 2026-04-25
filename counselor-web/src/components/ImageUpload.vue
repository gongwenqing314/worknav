<template>
  <!-- 图片上传组件：支持预览、删除、大小限制 -->
  <div class="image-upload">
    <!-- 已上传的图片预览 -->
    <div v-if="modelValue" class="image-preview">
      <el-image
        :src="modelValue"
        fit="cover"
        class="preview-img"
        :preview-src-list="[modelValue]"
        preview-teleported
      />
      <div class="preview-actions">
        <el-button type="danger" size="small" :icon="Delete" circle @click="removeImage" />
      </div>
    </div>

    <!-- 上传按钮（无图片时显示） -->
    <el-upload
      v-else
      :action="uploadUrl"
      :headers="uploadHeaders"
      :show-file-list="false"
      :before-upload="beforeUpload"
      :on-success="onSuccess"
      :on-error="onError"
      :accept="accept"
      :drag="drag"
      class="upload-area"
    >
      <div class="upload-trigger">
        <el-icon :size="32" color="#C0C4CC"><Plus /></el-icon>
        <span class="upload-text">{{ drag ? '拖拽或点击上传' : '点击上传' }}</span>
        <span class="upload-tip">支持 JPG/PNG/GIF，最大 {{ maxSizeLabel }}</span>
      </div>
    </el-upload>
  </div>
</template>

<script setup>
/**
 * ImageUpload - 图片上传组件
 * 支持图片预览、删除、文件大小和类型限制
 */
import { computed } from 'vue'
import { ElMessage } from 'element-plus'
import { Plus, Delete } from '@element-plus/icons-vue'
import { formatFileSize } from '@/utils/helpers'

const props = defineProps({
  // 图片 URL（v-model）
  modelValue: {
    type: String,
    default: ''
  },
  // 上传地址
  action: {
    type: String,
    default: ''
  },
  // 最大文件大小（字节）
  maxSize: {
    type: Number,
    default: 10 * 1024 * 1024 // 10MB
  },
  // 允许的文件类型
  accept: {
    type: String,
    default: '.jpg,.jpeg,.png,.gif,.webp'
  },
  // 是否支持拖拽上传
  drag: {
    type: Boolean,
    default: false
  },
  // 图片宽度
  width: {
    type: String,
    default: '120px'
  },
  // 图片高度
  height: {
    type: String,
    default: '120px'
  }
})

const emit = defineEmits(['update:modelValue', 'success'])

// 上传地址
const uploadUrl = computed(() => props.action || import.meta.env.VITE_UPLOAD_URL || '/api/upload')

// 上传请求头
const uploadHeaders = {
  Authorization: `Bearer ${localStorage.getItem('token') || ''}`
}

// 最大文件大小标签
const maxSizeLabel = computed(() => formatFileSize(props.maxSize))

/**
 * 上传前校验
 */
function beforeUpload(file) {
  // 校验文件类型
  const isValidType = props.accept.split(',').some(ext => {
    const regex = new RegExp(ext.replace('.', '\\.').replace('*', '.*'), 'i')
    return regex.test(file.name)
  })
  if (!isValidType) {
    ElMessage.error('请上传正确格式的图片文件')
    return false
  }

  // 校验文件大小
  if (file.size > props.maxSize) {
    ElMessage.error(`图片大小不能超过 ${maxSizeLabel.value}`)
    return false
  }

  return true
}

/**
 * 上传成功回调
 */
function onSuccess(response) {
  const url = response?.data?.url || response?.url
  if (url) {
    emit('update:modelValue', url)
    emit('success', url)
  } else {
    ElMessage.error('上传失败，未获取到图片地址')
  }
}

/**
 * 上传失败回调
 */
function onError() {
  ElMessage.error('图片上传失败，请重试')
}

/**
 * 删除已上传图片
 */
function removeImage() {
  emit('update:modelValue', '')
}
</script>

<style scoped>
.image-upload {
  display: inline-block;
}

/* ===== 图片预览 ===== */
.image-preview {
  position: relative;
  width: v-bind(width);
  height: v-bind(height);
  border-radius: 6px;
  overflow: hidden;
  border: 1px solid var(--color-border-light);
}

.preview-img {
  width: 100%;
  height: 100%;
}

.preview-actions {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.4);
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 0;
  transition: opacity 0.2s;
}

.image-preview:hover .preview-actions {
  opacity: 1;
}

/* ===== 上传区域 ===== */
.upload-area {
  width: v-bind(width);
  height: v-bind(height);
}

.upload-area :deep(.el-upload) {
  width: 100%;
  height: 100%;
}

.upload-area :deep(.el-upload-dragger) {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 8px;
}

.upload-trigger {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
}

.upload-text {
  font-size: 12px;
  color: #606266;
}

.upload-tip {
  font-size: 11px;
  color: #C0C4CC;
}
</style>
