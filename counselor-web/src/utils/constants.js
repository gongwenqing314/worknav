/**
 * 常量定义
 * 统一管理项目中使用的常量值
 */

// ===== 用户角色 =====
export const ROLES = {
  ADMIN: 'admin',           // 管理员
  COUNSELOR: 'counselor',   // 主管理辅导员
  ASSISTANT: 'assistant'    // 协管辅导员
}

// ===== 角色名称映射 =====
export const ROLE_LABELS = {
  [ROLES.ADMIN]: '管理员',
  [ROLES.COUNSELOR]: '辅导员',
  [ROLES.ASSISTANT]: '协管辅导员'
}

// ===== 任务状态 =====
export const TASK_STATUS = {
  DRAFT: 'draft',           // 草稿
  PENDING: 'pending',       // 待执行
  IN_PROGRESS: 'in_progress', // 执行中
  COMPLETED: 'completed',   // 已完成
  CANCELLED: 'cancelled'    // 已取消
}

// ===== 任务状态标签 =====
export const TASK_STATUS_LABELS = {
  [TASK_STATUS.DRAFT]: '草稿',
  [TASK_STATUS.PENDING]: '待执行',
  [TASK_STATUS.IN_PROGRESS]: '执行中',
  [TASK_STATUS.COMPLETED]: '已完成',
  [TASK_STATUS.CANCELLED]: '已取消'
}

// ===== 任务状态颜色 =====
export const TASK_STATUS_COLORS = {
  [TASK_STATUS.DRAFT]: 'info',
  [TASK_STATUS.PENDING]: 'warning',
  [TASK_STATUS.IN_PROGRESS]: 'primary',
  [TASK_STATUS.COMPLETED]: 'success',
  [TASK_STATUS.CANCELLED]: 'danger'
}

// ===== 情绪类型 =====
export const EMOTIONS = {
  HAPPY: 'happy',           // 开心
  CALM: 'calm',             // 平静
  ANXIOUS: 'anxious',       // 焦虑
  ANGRY: 'angry',           // 愤怒
  SAD: 'sad',               // 悲伤
  CONFUSED: 'confused'      // 困惑
}

// ===== 情绪标签 =====
export const EMOTION_LABELS = {
  [EMOTIONS.HAPPY]: '开心',
  [EMOTIONS.CALM]: '平静',
  [EMOTIONS.ANXIOUS]: '焦虑',
  [EMOTIONS.ANGRY]: '愤怒',
  [EMOTIONS.SAD]: '悲伤',
  [EMOTIONS.CONFUSED]: '困惑'
}

// ===== 情绪颜色 =====
export const EMOTION_COLORS = {
  [EMOTIONS.HAPPY]: '#67C23A',
  [EMOTIONS.CALM]: '#409EFF',
  [EMOTIONS.ANXIOUS]: '#E6A23C',
  [EMOTIONS.ANGRY]: '#F56C6C',
  [EMOTIONS.SAD]: '#909399',
  [EMOTIONS.CONFUSED]: '#B37FEB'
}

// ===== 预警级别 =====
export const ALERT_LEVELS = {
  LOW: 'low',               // 低
  MEDIUM: 'medium',         // 中
  HIGH: 'high'              // 高
}

// ===== 预警级别标签 =====
export const ALERT_LEVEL_LABELS = {
  [ALERT_LEVELS.LOW]: '低',
  [ALERT_LEVELS.MEDIUM]: '中',
  [ALERT_LEVELS.HIGH]: '高'
}

// ===== 预警级别颜色 =====
export const ALERT_LEVEL_COLORS = {
  [ALERT_LEVELS.LOW]: 'warning',
  [ALERT_LEVELS.MEDIUM]: 'danger',
  [ALERT_LEVELS.HIGH]: 'danger'
}

// ===== 通知类型 =====
export const NOTIFICATION_TYPES = {
  SYSTEM: 'system',         // 系统通知
  TASK: 'task',             // 任务通知
  EMOTION: 'emotion',       // 情绪预警
  VOICE_CHEER: 'voice_cheer', // 语音鼓励
  REMOTE_ASSIST: 'remote_assist' // 远程协助
}

// ===== 通知类型标签 =====
export const NOTIFICATION_TYPE_LABELS = {
  [NOTIFICATION_TYPES.SYSTEM]: '系统通知',
  [NOTIFICATION_TYPES.TASK]: '任务通知',
  [NOTIFICATION_TYPES.EMOTION]: '情绪预警',
  [NOTIFICATION_TYPES.VOICE_CHEER]: '语音鼓励',
  [NOTIFICATION_TYPES.REMOTE_ASSIST]: '远程协助'
}

// ===== 远程协助状态 =====
export const ASSIST_STATUS = {
  PENDING: 'pending',       // 待处理
  ACCEPTED: 'accepted',     // 已接受
  IN_PROGRESS: 'in_progress', // 进行中
  COMPLETED: 'completed',   // 已完成
  REJECTED: 'rejected'      // 已拒绝
}

// ===== 协助状态标签 =====
export const ASSIST_STATUS_LABELS = {
  [ASSIST_STATUS.PENDING]: '待处理',
  [ASSIST_STATUS.ACCEPTED]: '已接受',
  [ASSIST_STATUS.IN_PROGRESS]: '进行中',
  [ASSIST_STATUS.COMPLETED]: '已完成',
  [ASSIST_STATUS.REJECTED]: '已拒绝'
}

// ===== 设备状态 =====
export const DEVICE_STATUS = {
  ONLINE: 'online',         // 在线
  OFFLINE: 'offline',       // 离线
  LOCKED: 'locked'          // 已锁定
}

// ===== 设备状态标签 =====
export const DEVICE_STATUS_LABELS = {
  [DEVICE_STATUS.ONLINE]: '在线',
  [DEVICE_STATUS.OFFLINE]: '离线',
  [DEVICE_STATUS.LOCKED]: '已锁定'
}

// ===== 文件上传限制 =====
export const UPLOAD_LIMITS = {
  IMAGE_MAX_SIZE: 10 * 1024 * 1024,  // 图片最大 10MB
  AUDIO_MAX_SIZE: 20 * 1024 * 1024,  // 音频最大 20MB
  VIDEO_MAX_SIZE: 50 * 1024 * 1024,  // 视频最大 50MB
  ACCEPT_IMAGE: '.jpg,.jpeg,.png,.gif,.webp',
  ACCEPT_AUDIO: '.mp3,.wav,.m4a,.ogg',
  ACCEPT_VIDEO: '.mp4,.mov,.avi'
}

// ===== 分页默认值 =====
export const PAGINATION = {
  PAGE: 1,
  PAGE_SIZE: 20,
  PAGE_SIZES: [10, 20, 50, 100]
}

// ===== 日期格式 =====
export const DATE_FORMATS = {
  DATE: 'YYYY-MM-DD',
  TIME: 'HH:mm',
  DATETIME: 'YYYY-MM-DD HH:mm:ss',
  MONTH: 'YYYY-MM',
  HOUR: 'YYYY-MM-DD HH:00'
}
