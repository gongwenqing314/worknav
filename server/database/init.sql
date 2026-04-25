-- ============================================================
-- 工作导航（StepByStep）数据库初始化脚本
-- MySQL 8.0+
-- ============================================================

CREATE DATABASE IF NOT EXISTS worknav
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE worknav;

-- ============================================================
-- 1. 用户表
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
  id            BIGINT AUTO_INCREMENT PRIMARY KEY,
  username      VARCHAR(50)  NOT NULL UNIQUE COMMENT '用户名',
  password_hash VARCHAR(255) NOT NULL COMMENT '密码哈希',
  real_name     VARCHAR(50)  NOT NULL COMMENT '真实姓名',
  gender        ENUM('male', 'female') DEFAULT NULL COMMENT '性别',
  birth_date    DATE         DEFAULT NULL COMMENT '出生日期',
  phone         VARCHAR(20)  DEFAULT NULL COMMENT '手机号',
  avatar        VARCHAR(500) DEFAULT NULL COMMENT '头像URL',
  role          ENUM('counselor', 'co_counselor', 'parent', 'employee', 'employer') NOT NULL COMMENT '角色：辅导员/协管员/家长/员工/雇主',
  status        TINYINT      NOT NULL DEFAULT 1 COMMENT '状态：0-禁用 1-启用',
  last_login_at DATETIME     DEFAULT NULL COMMENT '最后登录时间',
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_role (role),
  INDEX idx_status (status),
  INDEX idx_phone (phone)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- ============================================================
-- 2. 员工档案表
-- ============================================================
CREATE TABLE IF NOT EXISTS employee_profiles (
  id              BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id         BIGINT       NOT NULL UNIQUE COMMENT '关联用户ID',
  disability_type VARCHAR(50)  DEFAULT NULL COMMENT '残疾类型',
  group_id        BIGINT       DEFAULT NULL COMMENT '所属分组ID',
  support_level   TINYINT      DEFAULT NULL COMMENT '支持等级(1-5)',
  workplace       VARCHAR(100) DEFAULT NULL COMMENT '工作场所',
  job_title       VARCHAR(50)  DEFAULT NULL COMMENT '岗位',
  emergency_contact VARCHAR(50) DEFAULT NULL COMMENT '紧急联系人',
  emergency_phone   VARCHAR(20) DEFAULT NULL COMMENT '紧急联系电话',
  notes           TEXT         DEFAULT NULL COMMENT '备注',
  created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_user_id (user_id),
  INDEX idx_workplace (workplace),
  INDEX idx_group_id (group_id),
  CONSTRAINT fk_profile_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='员工档案表';

-- ============================================================
-- 3. 员工分组表
-- ============================================================
CREATE TABLE IF NOT EXISTS employee_groups (
  id           BIGINT AUTO_INCREMENT PRIMARY KEY,
  name         VARCHAR(100) NOT NULL COMMENT '分组名称',
  description  VARCHAR(500) DEFAULT NULL COMMENT '分组描述',
  created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='员工分组表';

-- ============================================================
-- 4. 员工-辅导员关联表
-- ============================================================
CREATE TABLE IF NOT EXISTS employee_counselor (
  id           BIGINT AUTO_INCREMENT PRIMARY KEY,
  employee_id  BIGINT NOT NULL COMMENT '员工用户ID',
  counselor_id BIGINT NOT NULL COMMENT '辅导员用户ID',
  is_primary   TINYINT NOT NULL DEFAULT 0 COMMENT '是否主辅导员 0-否 1-是',
  created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_employee_counselor (employee_id, counselor_id),
  INDEX idx_counselor (counselor_id),
  CONSTRAINT fk_ec_employee FOREIGN KEY (employee_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_ec_counselor FOREIGN KEY (counselor_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='员工-辅导员关联表';

-- ============================================================
-- 5. 员工-家长关联表
-- ============================================================
CREATE TABLE IF NOT EXISTS employee_parent (
  id          BIGINT AUTO_INCREMENT PRIMARY KEY,
  employee_id BIGINT NOT NULL COMMENT '员工用户ID',
  parent_id   BIGINT NOT NULL COMMENT '家长用户ID',
  relation    VARCHAR(50) DEFAULT NULL COMMENT '关系描述（父亲/母亲/监护人等）',
  status      ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending' COMMENT '审核状态',
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_employee_parent (employee_id, parent_id),
  INDEX idx_parent (parent_id),
  INDEX idx_status (status),
  CONSTRAINT fk_ep_employee FOREIGN KEY (employee_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_ep_parent FOREIGN KEY (parent_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='员工-家长关联表';

-- ============================================================
-- 6. 任务模板表
-- ============================================================
CREATE TABLE IF NOT EXISTS task_templates (
  id            BIGINT AUTO_INCREMENT PRIMARY KEY,
  creator_id    BIGINT       NOT NULL COMMENT '创建者用户ID',
  title         VARCHAR(200) NOT NULL COMMENT '模板标题',
  description   TEXT         DEFAULT NULL COMMENT '模板描述',
  cover_image   VARCHAR(500) DEFAULT NULL COMMENT '封面图片URL',
  category      VARCHAR(100) DEFAULT NULL COMMENT '任务分类',
  is_public     TINYINT      NOT NULL DEFAULT 0 COMMENT '是否公开 0-私有 1-公开',
  status        TINYINT      NOT NULL DEFAULT 1 COMMENT '状态 0-草稿 1-启用',
  estimated_minutes INT      DEFAULT NULL COMMENT '预计耗时（分钟）',
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_creator (creator_id),
  INDEX idx_category (category),
  INDEX idx_public (is_public),
  CONSTRAINT fk_template_creator FOREIGN KEY (creator_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='任务模板表';

-- ============================================================
-- 7. 模板步骤表
-- ============================================================
CREATE TABLE IF NOT EXISTS template_steps (
  id              BIGINT AUTO_INCREMENT PRIMARY KEY,
  template_id     BIGINT       NOT NULL COMMENT '模板ID',
  step_order      INT          NOT NULL COMMENT '步骤顺序',
  title           VARCHAR(200) NOT NULL COMMENT '步骤标题',
  description     TEXT         DEFAULT NULL COMMENT '步骤描述',
  image_url       VARCHAR(500) DEFAULT NULL COMMENT '步骤配图URL',
  audio_url       VARCHAR(500) DEFAULT NULL COMMENT '语音提示URL',
  tip             VARCHAR(500) DEFAULT NULL COMMENT '小贴士',
  estimated_seconds INT        DEFAULT NULL COMMENT '预计耗时（秒）',
  created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_template (template_id),
  INDEX idx_order (template_id, step_order),
  CONSTRAINT fk_step_template FOREIGN KEY (template_id) REFERENCES task_templates(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='模板步骤表';

-- ============================================================
-- 8. 任务实例表
-- ============================================================
CREATE TABLE IF NOT EXISTS task_instances (
  id              BIGINT AUTO_INCREMENT PRIMARY KEY,
  template_id     BIGINT       NOT NULL COMMENT '模板ID',
  employee_id     BIGINT       NOT NULL COMMENT '执行员工ID',
  assigned_by     BIGINT       DEFAULT NULL COMMENT '分配者ID',
  status          ENUM('assigned', 'in_progress', 'paused', 'completed', 'cancelled') NOT NULL DEFAULT 'assigned' COMMENT '任务状态',
  scheduled_date  DATE         DEFAULT NULL COMMENT '排班日期',
  scheduled_time  TIME         DEFAULT NULL COMMENT '排班时间',
  started_at      DATETIME     DEFAULT NULL COMMENT '实际开始时间',
  completed_at    DATETIME     DEFAULT NULL COMMENT '实际完成时间',
  completion_note TEXT         DEFAULT NULL COMMENT '完成备注',
  created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_employee (employee_id),
  INDEX idx_template (template_id),
  INDEX idx_status (status),
  INDEX idx_scheduled (scheduled_date, scheduled_time),
  INDEX idx_assigned_by (assigned_by),
  CONSTRAINT fk_instance_template FOREIGN KEY (template_id) REFERENCES task_templates(id) ON DELETE CASCADE,
  CONSTRAINT fk_instance_employee FOREIGN KEY (employee_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_instance_assigner FOREIGN KEY (assigned_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='任务实例表';

-- ============================================================
-- 9. 步骤执行记录表
-- ============================================================
CREATE TABLE IF NOT EXISTS step_executions (
  id              BIGINT AUTO_INCREMENT PRIMARY KEY,
  instance_id     BIGINT       NOT NULL COMMENT '任务实例ID',
  step_id         BIGINT       NOT NULL COMMENT '模板步骤ID',
  status          ENUM('pending', 'in_progress', 'completed', 'skipped', 'failed') NOT NULL DEFAULT 'pending' COMMENT '步骤状态',
  started_at      DATETIME     DEFAULT NULL COMMENT '开始时间',
  completed_at    DATETIME     DEFAULT NULL COMMENT '完成时间',
  duration_seconds INT         DEFAULT NULL COMMENT '实际耗时（秒）',
  attempt_count   INT          NOT NULL DEFAULT 0 COMMENT '尝试次数',
  note            TEXT         DEFAULT NULL COMMENT '备注',
  created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_instance (instance_id),
  INDEX idx_step (step_id),
  INDEX idx_status (status),
  CONSTRAINT fk_exec_instance FOREIGN KEY (instance_id) REFERENCES task_instances(id) ON DELETE CASCADE,
  CONSTRAINT fk_exec_step FOREIGN KEY (step_id) REFERENCES template_steps(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='步骤执行记录表';

-- ============================================================
-- 10. 情绪记录表
-- ============================================================
CREATE TABLE IF NOT EXISTS emotion_records (
  id            BIGINT AUTO_INCREMENT PRIMARY KEY,
  employee_id   BIGINT       NOT NULL COMMENT '员工用户ID',
  emotion_type  ENUM('happy', 'calm', 'anxious', 'sad', 'angry', 'confused') NOT NULL COMMENT '情绪类型',
  intensity     TINYINT      NOT NULL DEFAULT 3 COMMENT '情绪强度 1-5',
  trigger       VARCHAR(500) DEFAULT NULL COMMENT '触发原因',
  note          TEXT         DEFAULT NULL COMMENT '备注',
  recorded_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录时间',
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_employee (employee_id),
  INDEX idx_emotion_type (emotion_type),
  INDEX idx_recorded_at (recorded_at),
  CONSTRAINT fk_emotion_employee FOREIGN KEY (employee_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='情绪记录表';

-- ============================================================
-- 11. 情绪预警规则表
-- ============================================================
CREATE TABLE IF NOT EXISTS emotion_alert_rules (
  id              BIGINT AUTO_INCREMENT PRIMARY KEY,
  employee_id     BIGINT       DEFAULT NULL COMMENT '员工ID（NULL表示全局规则）',
  negative_types  JSON         NOT NULL COMMENT '消极情绪类型列表',
  consecutive_days INT         NOT NULL DEFAULT 3 COMMENT '连续天数阈值',
  min_intensity   TINYINT      NOT NULL DEFAULT 3 COMMENT '最低强度阈值',
  notify_counselor TINYINT     NOT NULL DEFAULT 1 COMMENT '是否通知辅导员',
  notify_parent   TINYINT      NOT NULL DEFAULT 1 COMMENT '是否通知家长',
  is_active       TINYINT      NOT NULL DEFAULT 1 COMMENT '是否启用',
  created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_employee (employee_id),
  INDEX idx_active (is_active),
  CONSTRAINT fk_alert_employee FOREIGN KEY (employee_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='情绪预警规则表';

-- ============================================================
-- 11. 沟通板分类表
-- ============================================================
CREATE TABLE IF NOT EXISTS comm_categories (
  id          BIGINT AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(100) NOT NULL COMMENT '分类名称',
  icon        VARCHAR(200) DEFAULT NULL COMMENT '分类图标URL',
  sort_order  INT          NOT NULL DEFAULT 0 COMMENT '排序序号',
  is_deleted  TINYINT      NOT NULL DEFAULT 0 COMMENT '是否删除 0-否 1-是',
  created_by  BIGINT       DEFAULT NULL COMMENT '创建者ID',
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_sort (sort_order),
  INDEX idx_deleted (is_deleted),
  CONSTRAINT fk_comm_category_creator FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='沟通板分类表';

-- ============================================================
-- 12. 沟通常用语表
-- ============================================================
CREATE TABLE IF NOT EXISTS comm_phrases (
  id          BIGINT AUTO_INCREMENT PRIMARY KEY,
  category_id BIGINT       NOT NULL COMMENT '分类ID',
  text        VARCHAR(500) NOT NULL COMMENT '常用语文本',
  image_url   VARCHAR(500) DEFAULT NULL COMMENT '配图URL',
  audio_url   VARCHAR(500) DEFAULT NULL COMMENT '语音URL',
  sort_order  INT          NOT NULL DEFAULT 0 COMMENT '排序序号',
  is_deleted  TINYINT      NOT NULL DEFAULT 0 COMMENT '是否删除 0-否 1-是',
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_category (category_id),
  INDEX idx_sort (category_id, sort_order),
  CONSTRAINT fk_phrase_category FOREIGN KEY (category_id) REFERENCES comm_categories(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='沟通常用语表';

-- ============================================================
-- 13. 消息通知表
-- ============================================================
CREATE TABLE IF NOT EXISTS notifications (
  id          BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id     BIGINT       NOT NULL COMMENT '接收用户ID',
  type        ENUM('task_assigned', 'task_reminder', 'emotion_alert', 'voice_cheer', 'system', 'assist_request', 'assist_message') NOT NULL COMMENT '通知类型',
  title       VARCHAR(200) NOT NULL COMMENT '通知标题',
  content     TEXT         DEFAULT NULL COMMENT '通知内容',
  data        JSON         DEFAULT NULL COMMENT '附加数据',
  is_read     TINYINT      NOT NULL DEFAULT 0 COMMENT '是否已读 0-未读 1-已读',
  read_at     DATETIME     DEFAULT NULL COMMENT '阅读时间',
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_user (user_id),
  INDEX idx_type (type),
  INDEX idx_read (is_read),
  INDEX idx_created (created_at),
  CONSTRAINT fk_notification_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='消息通知表';

-- ============================================================
-- 14. 远程协助会话表
-- ============================================================
CREATE TABLE IF NOT EXISTS assist_sessions (
  id            BIGINT AUTO_INCREMENT PRIMARY KEY,
  employee_id   BIGINT       NOT NULL COMMENT '求助员工ID',
  helper_id     BIGINT       DEFAULT NULL COMMENT '协助辅导员ID',
  status        ENUM('pending', 'active', 'ended') NOT NULL DEFAULT 'pending' COMMENT '会话状态',
  request_type  VARCHAR(100) DEFAULT NULL COMMENT '请求类型',
  description   TEXT         DEFAULT NULL COMMENT '问题描述',
  photo_url     VARCHAR(500) DEFAULT NULL COMMENT '现场照片URL',
  annotation_url VARCHAR(500) DEFAULT NULL COMMENT '标注图片URL',
  started_at    DATETIME     DEFAULT NULL COMMENT '开始时间',
  ended_at      DATETIME     DEFAULT NULL COMMENT '结束时间',
  rating        TINYINT      DEFAULT NULL COMMENT '评价评分 1-5',
  feedback      TEXT         DEFAULT NULL COMMENT '评价反馈',
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_employee (employee_id),
  INDEX idx_helper (helper_id),
  INDEX idx_status (status),
  CONSTRAINT fk_assist_employee FOREIGN KEY (employee_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_assist_helper FOREIGN KEY (helper_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='远程协助会话表';

-- ============================================================
-- 15. 远程协助消息表
-- ============================================================
CREATE TABLE IF NOT EXISTS assist_messages (
  id            BIGINT AUTO_INCREMENT PRIMARY KEY,
  session_id    BIGINT       NOT NULL COMMENT '会话ID',
  sender_id     BIGINT       NOT NULL COMMENT '发送者用户ID',
  sender_role   ENUM('employee', 'counselor', 'co_counselor') NOT NULL COMMENT '发送者角色',
  type          ENUM('text', 'image', 'annotation', 'voice') NOT NULL DEFAULT 'text' COMMENT '消息类型',
  content       TEXT         DEFAULT NULL COMMENT '消息内容',
  file_url      VARCHAR(500) DEFAULT NULL COMMENT '文件URL',
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_session (session_id),
  INDEX idx_sender (sender_id),
  CONSTRAINT fk_msg_session FOREIGN KEY (session_id) REFERENCES assist_sessions(id) ON DELETE CASCADE,
  CONSTRAINT fk_msg_sender FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='远程协助消息表';

-- ============================================================
-- 16. 应急记录表
-- ============================================================
CREATE TABLE IF NOT EXISTS emergency_records (
  id            BIGINT AUTO_INCREMENT PRIMARY KEY,
  employee_id   BIGINT       NOT NULL COMMENT '员工用户ID',
  type          VARCHAR(100) NOT NULL COMMENT '应急类型',
  description   TEXT         DEFAULT NULL COMMENT '情况描述',
  location      VARCHAR(200) DEFAULT NULL COMMENT '发生地点',
  handler_id    BIGINT       DEFAULT NULL COMMENT '处理人ID',
  status        ENUM('active', 'resolved') NOT NULL DEFAULT 'active' COMMENT '处理状态',
  resolution    TEXT         DEFAULT NULL COMMENT '处理结果',
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_employee (employee_id),
  INDEX idx_status (status),
  INDEX idx_handler (handler_id),
  CONSTRAINT fk_emergency_employee FOREIGN KEY (employee_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_emergency_handler FOREIGN KEY (handler_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='应急记录表';

-- ============================================================
-- 17. 同步队列表（离线同步用）
-- ============================================================
CREATE TABLE IF NOT EXISTS sync_queue (
  id            BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id       BIGINT       NOT NULL COMMENT '用户ID',
  device_id     VARCHAR(100) NOT NULL COMMENT '设备ID',
  action        VARCHAR(50)  NOT NULL COMMENT '操作类型（create/update/delete）',
  table_name    VARCHAR(100) NOT NULL COMMENT '表名',
  record_id     BIGINT       DEFAULT NULL COMMENT '记录ID',
  payload       JSON         NOT NULL COMMENT '操作数据',
  status        ENUM('pending', 'synced', 'failed') NOT NULL DEFAULT 'pending' COMMENT '同步状态',
  error_message VARCHAR(500) DEFAULT NULL COMMENT '错误信息',
  synced_at     DATETIME     DEFAULT NULL COMMENT '同步完成时间',
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_user_device (user_id, device_id),
  INDEX idx_status (status),
  INDEX idx_created (created_at),
  CONSTRAINT fk_sync_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='同步队列表';

-- ============================================================
-- 18. 设备绑定表
-- ============================================================
CREATE TABLE IF NOT EXISTS device_bindings (
  id            BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id       BIGINT       NOT NULL COMMENT '绑定用户ID',
  device_id     VARCHAR(100) NOT NULL COMMENT '设备唯一标识',
  device_name   VARCHAR(200) DEFAULT NULL COMMENT '设备名称',
  bind_code     VARCHAR(10)  DEFAULT NULL COMMENT '绑定码',
  is_bound      TINYINT      NOT NULL DEFAULT 1 COMMENT '是否已绑定 0-解绑 1-绑定',
  last_active_at DATETIME    DEFAULT NULL COMMENT '最后活跃时间',
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_device (device_id),
  INDEX idx_user (user_id),
  INDEX idx_bind_code (bind_code),
  CONSTRAINT fk_device_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='设备绑定表';
