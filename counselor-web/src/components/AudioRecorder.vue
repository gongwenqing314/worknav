<template>
  <!-- 录音组件：支持录制、回放、删除 -->
  <div class="audio-recorder">
    <!-- 录音按钮 -->
    <el-button
      v-if="!isRecording && !modelValue"
      type="primary"
      size="small"
      :icon="Microphone"
      @click="startRecording"
      :loading="isInitializing"
    >
      录音
    </el-button>

    <!-- 录音中状态 -->
    <div v-if="isRecording" class="recording-status">
      <span class="recording-dot"></span>
      <span class="recording-time">{{ formatTime(recordingDuration) }}</span>
      <el-button type="danger" size="small" @click="stopRecording" :icon="VideoPause">
        停止
      </el-button>
    </div>

    <!-- 已录制音频回放 -->
    <div v-if="modelValue && !isRecording" class="audio-playback">
      <el-button size="small" :icon="VideoPlay" circle @click="togglePlay" />
      <div class="audio-progress">
        <el-progress
          :percentage="playProgress"
          :stroke-width="6"
          :show-text="false"
          color="#409EFF"
        />
        <span class="audio-duration">{{ formatTime(currentPlayTime) }} / {{ formatTime(totalDuration) }}</span>
      </div>
      <el-button size="small" type="danger" :icon="Delete" circle plain @click="removeAudio" />
    </div>
  </div>
</template>

<script setup>
/**
 * AudioRecorder - 录音组件
 * 使用 MediaRecorder API 实现浏览器录音
 * 支持录制、回放、删除
 */
import { ref, onUnmounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Microphone, VideoPause, VideoPlay, Delete } from '@element-plus/icons-vue'

const props = defineProps({
  // 音频 URL（v-model）
  modelValue: {
    type: String,
    default: ''
  },
  // 最大录音时长（秒）
  maxDuration: {
    type: Number,
    default: 60
  }
})

const emit = defineEmits(['update:modelValue', 'recorded'])

// 录音状态
const isRecording = ref(false)
const isInitializing = ref(false)
const recordingDuration = ref(0)
let mediaRecorder = null
let recordingTimer = null
let audioChunks = []

// 回放状态
const isPlaying = ref(false)
const playProgress = ref(0)
const currentPlayTime = ref(0)
const totalDuration = ref(0)
let audioElement = null
let playTimer = null

/**
 * 开始录音
 */
async function startRecording() {
  isInitializing.value = true
  try {
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
    mediaRecorder = new MediaRecorder(stream, { mimeType: getSupportedMimeType() })
    audioChunks = []

    mediaRecorder.ondataavailable = (event) => {
      if (event.data.size > 0) {
        audioChunks.push(event.data)
      }
    }

    mediaRecorder.onstop = async () => {
      // 停止所有音轨
      stream.getTracks().forEach(track => track.stop())

      // 创建音频 Blob 并上传
      const blob = new Blob(audioChunks, { type: audioChunks[0]?.type || 'audio/webm' })
      await uploadAudio(blob)
    }

    mediaRecorder.start(100) // 每 100ms 收集一次数据
    isRecording.value = true
    recordingDuration.value = 0

    // 录音计时器
    recordingTimer = setInterval(() => {
      recordingDuration.value++
      if (recordingDuration.value >= props.maxDuration) {
        stopRecording()
        ElMessage.warning(`已达到最大录音时长 ${props.maxDuration} 秒`)
      }
    }, 1000)
  } catch (error) {
    console.error('录音初始化失败:', error)
    ElMessage.error('无法访问麦克风，请检查权限设置')
  } finally {
    isInitializing.value = false
  }
}

/**
 * 停止录音
 */
function stopRecording() {
  if (mediaRecorder && mediaRecorder.state !== 'inactive') {
    mediaRecorder.stop()
  }
  isRecording.value = false
  if (recordingTimer) {
    clearInterval(recordingTimer)
    recordingTimer = null
  }
}

/**
 * 上传录音文件
 */
async function uploadAudio(blob) {
  try {
    const formData = new FormData()
    formData.append('audio', blob, `recording_${Date.now()}.webm`)

    const uploadUrl = import.meta.env.VITE_UPLOAD_URL || '/api/upload'
    const token = localStorage.getItem('token') || ''
    const response = await fetch(uploadUrl, {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` },
      body: formData
    })

    const result = await response.json()
    const audioUrl = result?.data?.url || result?.url
    if (audioUrl) {
      emit('update:modelValue', audioUrl)
      emit('recorded', audioUrl)
      // 初始化回放
      initAudioPlayback(audioUrl)
    } else {
      ElMessage.error('录音上传失败')
    }
  } catch (error) {
    console.error('上传录音失败:', error)
    ElMessage.error('录音上传失败，请重试')
  }
}

/**
 * 初始化音频回放
 */
function initAudioPlayback(url) {
  if (audioElement) {
    audioElement.pause()
    audioElement = null
  }
  audioElement = new Audio(url)
  audioElement.addEventListener('loadedmetadata', () => {
    totalDuration.value = Math.floor(audioElement.duration)
  })
  audioElement.addEventListener('ended', () => {
    isPlaying.value = false
    playProgress.value = 0
    currentPlayTime.value = 0
    if (playTimer) clearInterval(playTimer)
  })
}

/**
 * 切换播放/暂停
 */
function togglePlay() {
  if (!audioElement) {
    if (props.modelValue) {
      initAudioPlayback(props.modelValue)
    }
    return
  }

  if (isPlaying.value) {
    audioElement.pause()
    isPlaying.value = false
    if (playTimer) clearInterval(playTimer)
  } else {
    audioElement.play()
    isPlaying.value = true
    playTimer = setInterval(() => {
      if (audioElement && audioElement.duration) {
        currentPlayTime.value = Math.floor(audioElement.currentTime)
        playProgress.value = Math.round((audioElement.currentTime / audioElement.duration) * 100)
      }
    }, 200)
  }
}

/**
 * 删除录音
 */
function removeAudio() {
  if (audioElement) {
    audioElement.pause()
    audioElement = null
  }
  if (playTimer) clearInterval(playTimer)
  isPlaying.value = false
  playProgress.value = 0
  currentPlayTime.value = 0
  totalDuration.value = 0
  emit('update:modelValue', '')
}

/**
 * 获取浏览器支持的 MIME 类型
 */
function getSupportedMimeType() {
  const types = ['audio/webm;codecs=opus', 'audio/webm', 'audio/ogg;codecs=opus', 'audio/mp4']
  for (const type of types) {
    if (MediaRecorder.isTypeSupported(type)) return type
  }
  return ''
}

/**
 * 格式化时间（秒 -> mm:ss）
 */
function formatTime(seconds) {
  const m = Math.floor(seconds / 60).toString().padStart(2, '0')
  const s = (seconds % 60).toString().padStart(2, '0')
  return `${m}:${s}`
}

// 组件卸载时清理资源
onUnmounted(() => {
  if (mediaRecorder && mediaRecorder.state !== 'inactive') {
    mediaRecorder.stop()
  }
  if (recordingTimer) clearInterval(recordingTimer)
  if (playTimer) clearInterval(playTimer)
  if (audioElement) audioElement.pause()
})
</script>

<style scoped>
.audio-recorder {
  display: inline-flex;
  align-items: center;
}

/* ===== 录音中状态 ===== */
.recording-status {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 4px 12px;
  background: #FEF0F0;
  border-radius: 20px;
  border: 1px solid #FDE2E2;
}

.recording-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #F56C6C;
  animation: pulse 1s infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.4; }
}

.recording-time {
  font-size: 13px;
  font-weight: 600;
  color: #F56C6C;
  font-variant-numeric: tabular-nums;
}

/* ===== 音频回放 ===== */
.audio-playback {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 4px 8px;
  background: #F0F9FF;
  border-radius: 20px;
  border: 1px solid #D9ECFF;
}

.audio-progress {
  display: flex;
  align-items: center;
  gap: 8px;
  min-width: 120px;
}

.audio-progress :deep(.el-progress) {
  flex: 1;
}

.audio-duration {
  font-size: 11px;
  color: #909399;
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
}
</style>
