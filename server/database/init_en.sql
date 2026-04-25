CREATE DATABASE IF NOT EXISTS worknav
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE worknav;

CREATE TABLE IF NOT EXISTS users (
  id            BIGINT AUTO_INCREMENT PRIMARY KEY,
  username      VARCHAR(50)  NOT NULL UNIQUE COMMENT 'username',
  password_hash VARCHAR(255) NOT NULL COMMENT 'password hash',
  real_name     VARCHAR(50)  NOT NULL COMMENT 'real name',
  phone         VARCHAR(20)  DEFAULT NULL COMMENT 'phone number',
  avatar        VARCHAR(500) DEFAULT NULL COMMENT 'avatar URL',
  role          ENUM('counselor', 'co_counselor', 'parent', 'employee', 'employer') NOT NULL COMMENT 'role',
  status        TINYINT      NOT NULL DEFAULT 1 COMMENT 'status: 0-disabled 1-enabled',
  last_login_at DATETIME     DEFAULT NULL COMMENT 'last login time',
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_role (role),
  INDEX idx_status (status),
  INDEX idx_phone (phone)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='users table';

CREATE TABLE IF NOT EXISTS employee_profiles (
  id              BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id         BIGINT       NOT NULL COMMENT 'user ID',
  disability_type VARCHAR(100) DEFAULT NULL COMMENT 'disability type',
  support_level   TINYINT      DEFAULT NULL COMMENT 'support level 1-5',
  workplace       VARCHAR(200) DEFAULT NULL COMMENT 'workplace',
  job_title       VARCHAR(100) DEFAULT NULL COMMENT 'job title',
  emergency_contact VARCHAR(50) DEFAULT NULL COMMENT 'emergency contact',
  emergency_phone   VARCHAR(20) DEFAULT NULL COMMENT 'emergency phone',
  notes           TEXT         DEFAULT NULL COMMENT 'notes',
  created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_user_id (user_id),
  INDEX idx_workplace (workplace),
  CONSTRAINT fk_profile_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='employee profiles table';

CREATE TABLE IF NOT EXISTS employee_counselor (
  id           BIGINT AUTO_INCREMENT PRIMARY KEY,
  employee_id  BIGINT NOT NULL COMMENT 'employee user ID',
  counselor_id BIGINT NOT NULL COMMENT 'counselor user ID',
  is_primary   TINYINT NOT NULL DEFAULT 0 COMMENT 'is primary counselor 0-no 1-yes',
  created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_employee_counselor (employee_id, counselor_id),
  INDEX idx_counselor (counselor_id),
  CONSTRAINT fk_ec_employee FOREIGN KEY (employee_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_ec_counselor FOREIGN KEY (counselor_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='employee-counselor relation table';

CREATE TABLE IF NOT EXISTS employee_parent (
  id          BIGINT AUTO_INCREMENT PRIMARY KEY,
  employee_id BIGINT NOT NULL COMMENT 'employee user ID',
  parent_id   BIGINT NOT NULL COMMENT 'parent user ID',
  relation    VARCHAR(50) DEFAULT NULL COMMENT 'relation description',
  status      ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending' COMMENT 'approval status',
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_employee_parent (employee_id, parent_id),
  INDEX idx_parent (parent_id),
  INDEX idx_status (status),
  CONSTRAINT fk_ep_employee FOREIGN KEY (employee_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_ep_parent FOREIGN KEY (parent_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='employee-parent relation table';

CREATE TABLE IF NOT EXISTS task_templates (
  id            BIGINT AUTO_INCREMENT PRIMARY KEY,
  creator_id    BIGINT       NOT NULL COMMENT 'creator user ID',
  title         VARCHAR(200) NOT NULL COMMENT 'template title',
  description   TEXT         DEFAULT NULL COMMENT 'template description',
  cover_image   VARCHAR(500) DEFAULT NULL COMMENT 'cover image URL',
  category      VARCHAR(100) DEFAULT NULL COMMENT 'task category',
  is_public     TINYINT      NOT NULL DEFAULT 0 COMMENT 'is public 0-private 1-public',
  status        TINYINT      NOT NULL DEFAULT 1 COMMENT 'status 0-draft 1-enabled',
  estimated_minutes INT      DEFAULT NULL COMMENT 'estimated duration (minutes)',
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_creator (creator_id),
  INDEX idx_category (category),
  INDEX idx_public (is_public),
  CONSTRAINT fk_template_creator FOREIGN KEY (creator_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='task templates table';

CREATE TABLE IF NOT EXISTS template_steps (
  id              BIGINT AUTO_INCREMENT PRIMARY KEY,
  template_id     BIGINT       NOT NULL COMMENT 'template ID',
  step_order      INT          NOT NULL COMMENT 'step order',
  title           VARCHAR(200) NOT NULL COMMENT 'step title',
  description     TEXT         DEFAULT NULL COMMENT 'step description',
  image_url       VARCHAR(500) DEFAULT NULL COMMENT 'step image URL',
  audio_url       VARCHAR(500) DEFAULT NULL COMMENT 'audio prompt URL',
  tip             VARCHAR(500) DEFAULT NULL COMMENT 'tips',
  estimated_seconds INT        DEFAULT NULL COMMENT 'estimated duration (seconds)',
  created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_template (template_id),
  INDEX idx_order (template_id, step_order),
  CONSTRAINT fk_step_template FOREIGN KEY (template_id) REFERENCES task_templates(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='template steps table';

CREATE TABLE IF NOT EXISTS task_instances (
  id              BIGINT AUTO_INCREMENT PRIMARY KEY,
  template_id     BIGINT       NOT NULL COMMENT 'template ID',
  employee_id     BIGINT       NOT NULL COMMENT 'employee ID',
  assigned_by     BIGINT       DEFAULT NULL COMMENT 'assigner ID',
  status          ENUM('assigned', 'in_progress', 'paused', 'completed', 'cancelled') NOT NULL DEFAULT 'assigned' COMMENT 'task status',
  scheduled_date  DATE         DEFAULT NULL COMMENT 'scheduled date',
  scheduled_time  TIME         DEFAULT NULL COMMENT 'scheduled time',
  started_at      DATETIME     DEFAULT NULL COMMENT 'actual start time',
  completed_at    DATETIME     DEFAULT NULL COMMENT 'actual completion time',
  completion_note TEXT         DEFAULT NULL COMMENT 'completion note',
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='task instances table';

CREATE TABLE IF NOT EXISTS step_executions (
  id              BIGINT AUTO_INCREMENT PRIMARY KEY,
  instance_id     BIGINT       NOT NULL COMMENT 'task instance ID',
  step_id         BIGINT       NOT NULL COMMENT 'template step ID',
  status          ENUM('pending', 'in_progress', 'completed', 'skipped', 'failed') NOT NULL DEFAULT 'pending' COMMENT 'step status',
  started_at      DATETIME     DEFAULT NULL COMMENT 'start time',
  completed_at    DATETIME     DEFAULT NULL COMMENT 'completion time',
  duration_seconds INT         DEFAULT NULL COMMENT 'actual duration (seconds)',
  attempt_count   INT          NOT NULL DEFAULT 0 COMMENT 'attempt count',
  note            TEXT         DEFAULT NULL COMMENT 'note',
  created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_instance (instance_id),
  INDEX idx_step (step_id),
  INDEX idx_status (status),
  CONSTRAINT fk_exec_instance FOREIGN KEY (instance_id) REFERENCES task_instances(id) ON DELETE CASCADE,
  CONSTRAINT fk_exec_step FOREIGN KEY (step_id) REFERENCES template_steps(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='step executions table';

CREATE TABLE IF NOT EXISTS emotion_records (
  id            BIGINT AUTO_INCREMENT PRIMARY KEY,
  employee_id   BIGINT       NOT NULL COMMENT 'employee user ID',
  emotion_type  ENUM('happy', 'calm', 'anxious', 'sad', 'angry', 'confused') NOT NULL COMMENT 'emotion type',
  intensity     TINYINT      NOT NULL DEFAULT 3 COMMENT 'emotion intensity 1-5',
  `trigger`     VARCHAR(500) DEFAULT NULL COMMENT 'trigger reason',
  note          TEXT         DEFAULT NULL COMMENT 'note',
  recorded_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'record time',
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_employee (employee_id),
  INDEX idx_emotion_type (emotion_type),
  INDEX idx_recorded_at (recorded_at),
  CONSTRAINT fk_emotion_employee FOREIGN KEY (employee_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='emotion records table';

CREATE TABLE IF NOT EXISTS emotion_alert_rules (
  id              BIGINT AUTO_INCREMENT PRIMARY KEY,
  employee_id     BIGINT       DEFAULT NULL COMMENT 'employee ID (NULL means global rule)',
  negative_types  JSON         NOT NULL COMMENT 'negative emotion types list',
  consecutive_days INT         NOT NULL DEFAULT 3 COMMENT 'consecutive days threshold',
  min_intensity   TINYINT      NOT NULL DEFAULT 3 COMMENT 'min intensity threshold',
  notify_counselor TINYINT     NOT NULL DEFAULT 1 COMMENT 'notify counselor',
  notify_parent   TINYINT      NOT NULL DEFAULT 1 COMMENT 'notify parent',
  is_active       TINYINT      NOT NULL DEFAULT 1 COMMENT 'is active',
  created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_employee (employee_id),
  INDEX idx_active (is_active),
  CONSTRAINT fk_alert_employee FOREIGN KEY (employee_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='emotion alert rules table';

CREATE TABLE IF NOT EXISTS comm_categories (
  id          BIGINT AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(100) NOT NULL COMMENT 'category name',
  icon        VARCHAR(200) DEFAULT NULL COMMENT 'category icon URL',
  sort_order  INT          NOT NULL DEFAULT 0 COMMENT 'sort order',
  is_deleted  TINYINT      NOT NULL DEFAULT 0 COMMENT 'is deleted 0-no 1-yes',
  created_by  BIGINT       DEFAULT NULL COMMENT 'creator ID',
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_sort (sort_order),
  INDEX idx_deleted (is_deleted),
  CONSTRAINT fk_comm_category_creator FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='communication categories table';

CREATE TABLE IF NOT EXISTS comm_phrases (
  id          BIGINT AUTO_INCREMENT PRIMARY KEY,
  category_id BIGINT       NOT NULL COMMENT 'category ID',
  text        VARCHAR(500) NOT NULL COMMENT 'phrase text',
  image_url   VARCHAR(500) DEFAULT NULL COMMENT 'image URL',
  audio_url   VARCHAR(500) DEFAULT NULL COMMENT 'audio URL',
  sort_order  INT          NOT NULL DEFAULT 0 COMMENT 'sort order',
  is_deleted  TINYINT      NOT NULL DEFAULT 0 COMMENT 'is deleted 0-no 1-yes',
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_category (category_id),
  INDEX idx_sort (category_id, sort_order),
  CONSTRAINT fk_phrase_category FOREIGN KEY (category_id) REFERENCES comm_categories(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='communication phrases table';

CREATE TABLE IF NOT EXISTS notifications (
  id          BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id     BIGINT       NOT NULL COMMENT 'receiver user ID',
  type        ENUM('task_assigned', 'task_reminder', 'emotion_alert', 'voice_cheer', 'system', 'assist_request', 'assist_message') NOT NULL COMMENT 'notification type',
  title       VARCHAR(200) NOT NULL COMMENT 'notification title',
  content     TEXT         DEFAULT NULL COMMENT 'notification content',
  data        JSON         DEFAULT NULL COMMENT 'additional data',
  is_read     TINYINT      NOT NULL DEFAULT 0 COMMENT 'is read 0-unread 1-read',
  read_at     DATETIME     DEFAULT NULL COMMENT 'read time',
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_user (user_id),
  INDEX idx_type (type),
  INDEX idx_read (is_read),
  INDEX idx_created (created_at),
  CONSTRAINT fk_notification_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='notifications table';

CREATE TABLE IF NOT EXISTS assist_sessions (
  id            BIGINT AUTO_INCREMENT PRIMARY KEY,
  employee_id   BIGINT       NOT NULL COMMENT 'employee ID',
  helper_id     BIGINT       DEFAULT NULL COMMENT 'helper counselor ID',
  status        ENUM('pending', 'active', 'ended') NOT NULL DEFAULT 'pending' COMMENT 'session status',
  request_type  VARCHAR(100) DEFAULT NULL COMMENT 'request type',
  description   TEXT         DEFAULT NULL COMMENT 'problem description',
  photo_url     VARCHAR(500) DEFAULT NULL COMMENT 'scene photo URL',
  annotation_url VARCHAR(500) DEFAULT NULL COMMENT 'annotated photo URL',
  started_at    DATETIME     DEFAULT NULL COMMENT 'start time',
  ended_at      DATETIME     DEFAULT NULL COMMENT 'end time',
  rating        TINYINT      DEFAULT NULL COMMENT 'rating 1-5',
  feedback      TEXT         DEFAULT NULL COMMENT 'feedback',
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_employee (employee_id),
  INDEX idx_helper (helper_id),
  INDEX idx_status (status),
  CONSTRAINT fk_assist_employee FOREIGN KEY (employee_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_assist_helper FOREIGN KEY (helper_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='remote assist sessions table';

CREATE TABLE IF NOT EXISTS assist_messages (
  id            BIGINT AUTO_INCREMENT PRIMARY KEY,
  session_id    BIGINT       NOT NULL COMMENT 'session ID',
  sender_id     BIGINT       NOT NULL COMMENT 'sender user ID',
  sender_role   ENUM('employee', 'counselor', 'co_counselor') NOT NULL COMMENT 'sender role',
  type          ENUM('text', 'image', 'annotation', 'voice') NOT NULL DEFAULT 'text' COMMENT 'message type',
  content       TEXT         DEFAULT NULL COMMENT 'message content',
  file_url      VARCHAR(500) DEFAULT NULL COMMENT 'file URL',
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_session (session_id),
  INDEX idx_sender (sender_id),
  CONSTRAINT fk_msg_session FOREIGN KEY (session_id) REFERENCES assist_sessions(id) ON DELETE CASCADE,
  CONSTRAINT fk_msg_sender FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='remote assist messages table';

CREATE TABLE IF NOT EXISTS emergency_records (
  id            BIGINT AUTO_INCREMENT PRIMARY KEY,
  employee_id   BIGINT       NOT NULL COMMENT 'employee user ID',
  type          VARCHAR(100) NOT NULL COMMENT 'emergency type',
  description   TEXT         DEFAULT NULL COMMENT 'situation description',
  location      VARCHAR(200) DEFAULT NULL COMMENT 'location',
  handler_id    BIGINT       DEFAULT NULL COMMENT 'handler ID',
  status        ENUM('active', 'resolved') NOT NULL DEFAULT 'active' COMMENT 'handling status',
  resolution    TEXT         DEFAULT NULL COMMENT 'resolution result',
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_employee (employee_id),
  INDEX idx_status (status),
  INDEX idx_handler (handler_id),
  CONSTRAINT fk_emergency_employee FOREIGN KEY (employee_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_emergency_handler FOREIGN KEY (handler_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='emergency records table';

CREATE TABLE IF NOT EXISTS sync_queue (
  id            BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id       BIGINT       NOT NULL COMMENT 'user ID',
  device_id     VARCHAR(100) NOT NULL COMMENT 'device ID',
  action        VARCHAR(50)  NOT NULL COMMENT 'operation type (create/update/delete)',
  table_name    VARCHAR(100) NOT NULL COMMENT 'table name',
  record_id     BIGINT       DEFAULT NULL COMMENT 'record ID',
  payload       JSON         NOT NULL COMMENT 'operation data',
  status        ENUM('pending', 'synced', 'failed') NOT NULL DEFAULT 'pending' COMMENT 'sync status',
  error_message VARCHAR(500) DEFAULT NULL COMMENT 'error message',
  synced_at     DATETIME     DEFAULT NULL COMMENT 'sync completion time',
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_user_device (user_id, device_id),
  INDEX idx_status (status),
  INDEX idx_created (created_at),
  CONSTRAINT fk_sync_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='sync queue table';

CREATE TABLE IF NOT EXISTS device_bindings (
  id            BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id       BIGINT       NOT NULL COMMENT 'bound user ID',
  device_id     VARCHAR(100) NOT NULL COMMENT 'device unique ID',
  device_name   VARCHAR(200) DEFAULT NULL COMMENT 'device name',
  bind_code     VARCHAR(10)  DEFAULT NULL COMMENT 'binding code',
  is_bound      TINYINT      NOT NULL DEFAULT 1 COMMENT 'is bound 0-unbound 1-bound',
  last_active_at DATETIME    DEFAULT NULL COMMENT 'last active time',
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_device (device_id),
  INDEX idx_user (user_id),
  INDEX idx_bind_code (bind_code),
  CONSTRAINT fk_device_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='device bindings table';
