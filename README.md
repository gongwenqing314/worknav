# 工作导航（StepByStep）

> **产品口号：每一步，我都能做到。**

一款专为心智障碍人士设计的职场支持应用，通过视觉化任务引导、沟通辅助、情绪管理和远程支持，帮助轻度心智障碍员工实现稳定就业。

---

## 目录

- [项目概述](#项目概述)
- [系统架构](#系统架构)
- [技术栈](#技术栈)
- [项目结构](#项目结构)
- [环境要求](#环境要求)
- [快速开始](#快速开始)
  - [1. 后端服务部署](#1-后端服务部署)
  - [2. 辅导员端 Web 部署](#2-辅导员端-web-部署)
  - [3. 员工端 APP 构建](#3-员工端-app-构建)
  - [4. 员工端 Web 构建（Flutter Web）](#4-员工端-web-构建flutter-web)
- [配置说明](#配置说明)
- [功能模块说明](#功能模块说明)
- [API 接口文档](#api-接口文档)
- [数据库设计](#数据库设计)
- [部署方案](#部署方案)
  - [开发环境](#开发环境)
  - [生产环境（国内云服务）](#生产环境国内云服务)
- [使用指南](#使用指南)
  - [辅导员端使用流程](#辅导员端使用流程)
  - [员工端使用流程](#员工端使用流程)
  - [家长端使用流程](#家长端使用流程)
- [离线模式说明](#离线模式说明)
- [无障碍设计说明](#无障碍设计说明)
- [安全设计](#安全设计)
- [常见问题](#常见问题)
- [项目文档](#项目文档)
- [许可证](#许可证)

---

## 项目概述

### 产品背景

我国有大量轻度心智障碍人士（如高功能孤独症谱系人士、轻度智力发育迟缓者）具备参与社会劳动的能力和意愿，但在记忆、执行、社交沟通方面存在一定困难，导致就业率偏低、在职稳定性不足。

### 目标用户

| 用户角色 | 说明 |
|----------|------|
| **心智障碍员工** | 使用员工端 APP，接收任务引导、沟通辅助和情绪支持 |
| **就业辅导员** | 使用 Web 管理后台，管理员工、创建任务、监控进度、远程协助 |
| **家长/监护人** | 通过 Web 端查看孩子的工作状态和情绪记录（只读权限） |
| **雇主** | 通过 Web 端查看员工任务完成概况（有限查看权限） |

### 核心功能

1. **任务拆解与视觉化流程导航** — 辅导员将工作拆解为可视化步骤，员工逐步执行
2. **沟通板与情绪温度计** — 常用语语音播报、情绪表达卡片、自动预警
3. **环境适应与即时支持** — 上下班提醒、应急卡片、远程协助
4. **数据统计与报表** — 任务完成率、卡顿热点分析、情绪趋势

---

## 系统架构

```
┌─────────────────────────────────────────────────────────┐
│                       客户端层                           │
│  ┌──────────────────┐  ┌──────────────┐  ┌────────────┐ │
│  │  Flutter 移动端   │  │  Flutter Web  │  │  Vue 3 Web │ │
│  │  (员工端 APP)     │  │ (员工端 Web)  │  │ (管理后台)  │ │
│  └────────┬─────────┘  └──────┬───────┘  └─────┬──────┘ │
└───────────┼───────────────────┼─────────────────┼────────┘
            │   HTTPS / WebSocket               │
┌───────────┼───────────────────┼─────────────────┼────────┐
│           ▼        服务层     ▼                 ▼        │
│  ┌──────────────────────────────────────────────────┐    │
│  │          Node.js + Express API 服务               │    │
│  │   ┌──────────┐ ┌──────────┐ ┌────────────────┐  │    │
│  │   │ 用户服务  │ │ 任务服务  │ │  消息/通知服务  │  │    │
│  │   └──────────┘ └──────────┘ └────────────────┘  │    │
│  │   ┌──────────┐ ┌──────────┐ ┌────────────────┐  │    │
│  │   │ 情绪服务  │ │ 统计服务  │ │  远程协助服务   │  │    │
│  │   └──────────┘ └──────────┘ └────────────────┘  │    │
│  └─────────────────────┬────────────────────────────┘    │
│                        │                                 │
│  ┌─────────────────────┼────────────────────────────┐    │
│  │          数据层      ▼                             │    │
│  │   ┌──────────┐          ┌──────────────┐         │    │
│  │   │  MySQL   │◄────────►│    Redis     │         │    │
│  │   └──────────┘          └──────────────┘         │    │
│  └──────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

> **Flutter Web 同源部署**：员工端 Flutter Web 构建产物部署在后端 `/employee-app/` 路径下，由 Express 静态文件服务直接托管，无需独立 Web 服务器，避免 CORS 跨域问题。

---

## 技术栈

| 层级 | 技术选型 | 版本 | 说明 |
|------|----------|------|------|
| 移动端（员工端） | Flutter + Dart | 3.10+ / 3.0+ | 跨平台开发，iOS + Android + Web |
| Web 端（辅导员端） | Vue 3 + Element Plus + Pinia | 3.4+ / 2.6+ | 管理后台 |
| 后端服务 | Node.js + Express | 18+ / 4.21+ | RESTful API + WebSocket |
| 数据库 | MySQL | 8.0+ | 关系型数据库 |
| 缓存 | Redis (ioredis) | 7.0+ | 会话/缓存/消息队列 |
| 实时通信 | Socket.IO | 4.7+ | WebSocket 消息推送 |
| 文件存储 | 云对象存储（OSS）/ 本地 | - | 图片/音频/视频 |
| 离线存储 | SQLite（移动端） | - | 本地数据缓存 |
| 部署环境 | 国内云服务 | - | 阿里云/腾讯云 |

---

## 项目结构

```
worknav/
├── server/                          # 后端服务（Node.js + Express）
│   ├── package.json
│   ├── .env.example                 # 环境变量模板
│   ├── seed.js                      # 种子数据脚本
│   ├── src/
│   │   ├── app.js                   # 应用入口（含 Flutter Web 静态服务）
│   │   ├── config/                  # 配置（数据库/Redis/JWT）
│   │   ├── controllers/             # 控制器（10 个模块）
│   │   ├── middlewares/             # 中间件（认证/权限/校验/错误处理）
│   │   ├── models/                  # 数据模型（19 个表）
│   │   ├── routes/                  # 路由定义（RESTful）
│   │   ├── services/                # 业务逻辑服务
│   │   ├── utils/                   # 工具函数
│   │   └── websocket/               # WebSocket 实时通信
│   ├── database/
│   │   └── init.sql                 # 数据库初始化脚本
│   ├── migrations/
│   │   └── seed.sql                 # 种子数据
│   └── public/
│       └── employee-app/            # Flutter Web 构建产物（同源部署）
│
├── employee-app/                    # 员工端 APP（Flutter）
│   ├── pubspec.yaml
│   ├── lib/
│   │   ├── main.dart                # 应用入口
│   │   ├── app.dart                 # MaterialApp 配置
│   │   ├── core/                    # 核心层（常量/网络/主题/工具）
│   │   │   ├── constants/           # API 地址、存储键名
│   │   │   ├── network/             # DioClient、SyncService
│   │   │   ├── theme/               # AppTheme（高对比度无障碍主题）
│   │   │   └── utils/               # StorageUtil、AudioPlayer
│   │   ├── features/                # 功能模块
│   │   │   ├── auth/                # 启动页/自动登录（设备登录）
│   │   │   ├── home/                # 主页/今日任务列表
│   │   │   ├── task/                # 任务执行/步骤引导
│   │   │   ├── communication/       # 沟通板
│   │   │   ├── emotion/             # 情绪温度计
│   │   │   ├── remote_assist/       # 远程协助
│   │   │   ├── reminders/           # 提醒服务
│   │   │   └── settings/            # 设置
│   │   └── shared/                  # 共享（模型/组件/服务）
│   │       ├── models/              # TaskInstance 等数据模型
│   │       ├── services/            # AuthService、TaskService 等
│   │       └── widgets/             # 通用 UI 组件
│   ├── assets/                      # 资源文件（图片/音频）
│   └── web/                         # Flutter Web 资源（index.html、图标）
│
├── counselor-web/                   # 辅导员端 Web（Vue 3）
│   ├── package.json
│   ├── vite.config.js
│   ├── src/
│   │   ├── main.js                  # 应用入口
│   │   ├── api/                     # API 接口层
│   │   ├── components/              # 通用组件
│   │   ├── composables/             # 组合式函数
│   │   ├── router/                  # 路由配置（22 个页面）
│   │   ├── stores/                  # Pinia 状态管理
│   │   ├── utils/                   # 工具函数
│   │   └── views/                   # 页面视图
│   └── public/                      # 静态资源
│
└── docs/                            # 项目文档
    ├── 需求文档_PRD.md
    ├── 设计方案.md
    └── 开发任务书.md
```

---

## 环境要求

### 后端服务

| 工具 | 版本要求 | 说明 |
|------|----------|------|
| Node.js | >= 18.0.0 | 推荐使用 LTS 版本 |
| npm | >= 9.0.0 | 或 yarn / pnpm |
| MySQL | >= 8.0 | 需创建数据库 |
| Redis | >= 7.0 | 用于缓存和会话管理 |

### 员工端 APP

| 工具 | 版本要求 | 说明 |
|------|----------|------|
| Flutter SDK | >= 3.10.0 | 稳定版 |
| Dart | >= 3.0.0 | Flutter 自带 |
| Xcode | >= 15.0 | iOS 构建需要（仅 macOS） |
| Android SDK | >= 33 | Android 构建需要 |
| Chrome | 最新版 | Flutter Web 调试 |

### 辅导员端 Web

| 工具 | 版本要求 | 说明 |
|------|----------|------|
| Node.js | >= 18.0.0 | 构建工具依赖 |
| npm | >= 9.0.0 | 或 yarn / pnpm |

---

## 快速开始

### 1. 后端服务部署

#### 1.1 安装依赖

```bash
cd server
npm install
```

#### 1.2 配置环境变量

```bash
cp .env.example .env
```

编辑 `.env` 文件，填入实际配置：

```env
# 服务配置
NODE_ENV=development
PORT=3000
API_PREFIX=/api/v1

# MySQL 数据库
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=worknav

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# JWT 密钥
JWT_SECRET=your_jwt_secret_key_at_least_32_chars
JWT_EXPIRES_IN=24h
JWT_REFRESH_SECRET=your_refresh_secret_key
JWT_REFRESH_EXPIRES_IN=7d

# 文件上传
UPLOAD_MAX_SIZE=50MB
OSS_ACCESS_KEY=your_oss_key
OSS_SECRET_KEY=your_oss_secret
OSS_BUCKET=worknav-files
OSS_REGION=oss-cn-hangzhou

# WebSocket
SOCKET_CORS_ORIGIN=http://localhost:5173,http://localhost:8080
```

#### 1.3 初始化数据库

```bash
# 登录 MySQL，创建数据库
mysql -u root -p -e "CREATE DATABASE worknav CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# 执行建表脚本
mysql -u root -p worknav < database/init.sql

# 导入种子数据（可选，包含测试账号和示例数据）
mysql -u root -p worknav < migrations/seed.sql
```

#### 1.4 启动服务

```bash
# 开发模式（热重载）
npm run dev

# 生产模式
npm start
```

服务启动后：
- API 地址：`http://localhost:3000/api/v1`
- WebSocket 地址：`ws://localhost:3000`
- 员工端 Web：`http://localhost:3000/employee-app/`
- 根路径健康检查：`http://localhost:3000/`

#### 1.5 验证服务

```bash
curl http://localhost:3000/
# 预期响应：{"code":200,"message":"工作导航 API 服务运行中","data":{...}}
```

---

### 2. 辅导员端 Web 部署

#### 2.1 安装依赖

```bash
cd counselor-web
npm install
```

#### 2.2 配置环境变量

开发环境配置已内置在 `.env.development` 中：

```env
VITE_API_BASE_URL=http://localhost:3000/api/v1
VITE_WS_URL=ws://localhost:3000
VITE_APP_TITLE=工作导航 - 管理后台
```

生产环境配置 `.env.production`：

```env
VITE_API_BASE_URL=https://your-domain.com/api/v1
VITE_WS_URL=wss://your-domain.com
VITE_APP_TITLE=工作导航 - 管理后台
```

#### 2.3 启动开发服务器

```bash
npm run dev
```

访问 `http://localhost:5173`，使用种子数据中的账号登录：

| 角色 | 手机号 | 密码 |
|------|--------|------|
| 辅导员（主管理） | 13800000001 | password123 |
| 辅导员（协管） | 13800000002 | password123 |
| 家长 | 13800000003 | password123 |

#### 2.4 构建生产版本

```bash
npm run build
```

构建产物在 `dist/` 目录，可部署到 Nginx/CDN。

---

### 3. 员工端 APP 构建

#### 3.1 安装 Flutter

```bash
# 参考 https://docs.flutter.dev/get-started/install
flutter doctor
```

#### 3.2 安装依赖

```bash
cd employee-app
flutter pub get
```

#### 3.3 配置 API 地址

编辑 `lib/core/constants/api_constants.dart`：

```dart
class ApiConstants {
  // 移动端开发环境（根据设备类型选择）
  static const String baseUrl = 'http://10.0.2.2:3000/api/v1'; // Android 模拟器
  // static const String baseUrl = 'http://localhost:3000/api/v1'; // iOS 模拟器

  // 生产环境
  // static const String baseUrl = 'https://your-domain.com/api/v1';

  static const String wsUrl = 'ws://10.0.2.2:3000';
}
```

> **注意**：Flutter Web 版本使用相对路径 `/api/v1`，无需手动配置 baseUrl（同源部署）。

#### 3.4 运行调试

```bash
# 检查连接的设备
flutter devices

# 运行在 Android 模拟器/真机
flutter run

# 运行在 iOS 模拟器（仅 macOS）
flutter run -d ios

# 运行在 Chrome（Web 调试）
flutter run -d chrome
```

#### 3.5 构建发布版本

```bash
# Android APK
flutter build apk --release

# Android App Bundle（推荐上架 Google Play）
flutter build appbundle --release

# iOS（需要 macOS + Xcode）
flutter build ios --release

# Web（部署到后端同源目录）
flutter build web --release --base-href "/employee-app/"
```

构建产物位置：
- Android APK: `build/app/outputs/flutter-apk/app-release.apk`
- iOS: `build/ios/iphoneos/Runner.app`
- Web: `build/web/`

---

### 4. 员工端 Web 构建（Flutter Web）

员工端 Flutter Web 采用**同源部署**方案，构建产物直接由后端 Express 静态文件服务托管。

#### 4.1 构建

```bash
cd employee-app
flutter build web --release --base-href "/employee-app/"
```

#### 4.2 部署到后端

将构建产物复制到后端静态文件目录：

```bash
cp -r build/web/* ../server/public/employee-app/
```

#### 4.3 访问

启动后端服务后，访问 `http://localhost:3000/employee-app/` 即可使用员工端 Web 版。

> **同源部署优势**：无需独立 Web 服务器，不存在 CORS 跨域问题，API 请求自动使用相对路径。

---

## 配置说明

### 后端核心配置项

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| `PORT` | 服务端口 | 3000 |
| `NODE_ENV` | 运行环境（development/production） | development |
| `JWT_SECRET` | JWT 签名密钥（**必须修改**） | - |
| `JWT_EXPIRES_IN` | Access Token 有效期 | 24h |
| `DB_HOST` | MySQL 地址 | localhost |
| `REDIS_HOST` | Redis 地址 | localhost |
| `UPLOAD_MAX_SIZE` | 文件上传大小限制 | 50MB |

### 员工端核心配置

| 配置项 | 文件 | 说明 |
|--------|------|------|
| API 地址（移动端） | `lib/core/constants/api_constants.dart` | 后端 API 基础 URL |
| API 地址（Web） | 自动使用相对路径 `/api/v1` | 同源部署，无需配置 |
| 主题色 | `lib/core/theme/app_theme.dart` | 主色调、字体大小 |
| 离线缓存 | `lib/core/network/sync_service.dart` | 同步间隔、队列大小 |

### 辅导员端核心配置

| 配置项 | 文件 | 说明 |
|--------|------|------|
| API 地址 | `.env.*` | VITE_API_BASE_URL |
| WebSocket | `.env.*` | VITE_WS_URL |
| 菜单权限 | `src/router/index.js` | 路由 meta.roles |

---

## 功能模块说明

### 模块一：任务拆解与视觉化流程导航

**辅导员端操作：**
1. 进入「任务模板管理」，点击「新建模板」
2. 输入任务名称，上传封面图片
3. 逐步添加步骤：上传图片/视频、输入说明文字、设置关键步骤
4. 保存模板后，在「排班管理」中将任务分配给员工

**员工端体验：**
1. 打开 APP，自动显示今日任务列表（大图标卡片、统计面板）
2. 点击任务进入步骤引导界面
3. 查看大图片 + 文字说明，完成操作后点击绿色大勾
4. 关键步骤自动播放语音提示 + 震动反馈
5. 所有步骤完成后显示庆祝动画

### 模块二：沟通板与情绪温度计

**沟通板：**
- 员工点击大图标按钮，APP 自动语音播报对应语句
- 辅导员可自定义常用语内容和分类
- 支持场景化配置（如咖啡店、超市等）

**情绪温度计：**
- 员工通过形象卡片选择当前情绪状态
- 系统自动监测：连续 3 次消极情绪 / 单步停留超时 3 倍 → 自动预警
- 辅导员和家长实时收到预警通知

### 模块三：环境适应与即时支持

**提醒服务：**
- 上下班提醒（提前 5 分钟 + 精确时间双重提醒）
- 休息提醒（强视觉化 + 语音播报）
- 未确认提醒自动通知辅导员

**远程协助（隐形辅导员）：**
1. 员工点击「拍照求助」，拍摄现场照片
2. 辅导员在 Web 端收到请求，在照片上圈画标注 + 录音说明
3. 标注结果实时回传到员工端

### 模块四：数据统计与报表

- 任务完成率趋势（折线图）
- 步骤耗时分析 / 卡顿热点排行（柱状图）
- 情绪记录统计（饼图 + 时间线）
- 报表导出（PDF 格式）

---

## API 接口文档

### 接口规范

- **基础路径**：`/api/v1`
- **认证方式**：Bearer Token（JWT）
- **响应格式**：

```json
{
  "code": 200,
  "message": "success",
  "data": {}
}
```

### 核心接口列表

#### 认证模块 (`/auth`)

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| POST | /auth/register | 用户注册 | 公开 |
| POST | /auth/login | 用户登录（用户名/手机号+密码） | 公开 |
| POST | /auth/device-login | 设备自动登录（员工端 Flutter Web） | 公开 |
| POST | /auth/refresh | 刷新 Token | 公开 |
| POST | /auth/logout | 登出 | 已认证 |
| PUT | /auth/password | 修改密码 | 已认证 |
| GET | /auth/me | 获取当前用户信息 | 已认证 |

#### 用户管理 (`/users`)

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | /users | 获取用户列表 | 辅导员 |
| GET | /users/:id | 获取用户详情 | 已认证 |
| PUT | /users/:id | 更新用户信息 | 已认证 |
| DELETE | /users/:id | 禁用用户 | 辅导员 |
| GET | /users/groups | 获取员工分组列表 | 已认证 |
| POST | /users/groups | 创建员工分组 | 辅导员 |
| POST | /users/employees | 创建员工（含账号和档案） | 辅导员 |
| PUT | /users/employees/:employeeId | 更新员工信息 | 辅导员 |
| DELETE | /users/employees/:employeeId | 删除员工 | 辅导员 |
| GET | /users/employees/list | 获取员工列表（含档案） | 辅导员 |
| GET | /users/employees/:employeeId/profile | 获取员工档案详情 | 可访问该员工 |
| POST | /users/employees/:employeeId/profile | 创建/更新员工档案 | 辅导员 |
| GET | /users/employees/:employeeId/counselors | 获取员工的辅导员列表 | 可访问该员工 |
| POST | /users/employees/:employeeId/counselors | 添加辅导员关联 | 辅导员 |
| DELETE | /users/employees/:employeeId/counselors/:counselorId | 删除辅导员关联 | 辅导员 |
| GET | /users/employees/:employeeId/parents | 获取员工的家长列表 | 可访问该员工 |
| POST | /users/employees/:employeeId/parents | 发起家长关联请求 | 辅导员 |
| GET | /users/employees/:employeeId/parent-requests | 获取待审核家长关联请求 | 可访问该员工 |
| PUT | /users/parents/requests/:requestId | 审核家长关联请求 | 已认证 |
| GET | /users/parents/my-employees | 获取家长关联的员工列表 | 家长 |

#### 任务管理 (`/tasks`)

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | /tasks/templates | 获取任务模板列表 | 已认证 |
| GET | /tasks/templates/:templateId | 获取任务模板详情 | 已认证 |
| POST | /tasks/templates | 创建任务模板 | 辅导员 |
| PUT | /tasks/templates/:templateId | 更新任务模板 | 辅导员 |
| DELETE | /tasks/templates/:templateId | 删除任务模板 | 辅导员 |
| GET | /tasks/today | 获取今日任务（员工端） | 员工 |
| GET | /tasks/instances | 获取任务实例列表 | 已认证 |
| GET | /tasks/instances/:instanceId | 获取任务实例详情 | 已认证 |
| PUT | /tasks/instances/:instanceId | 更新任务实例 | 辅导员 |
| DELETE | /tasks/instances/:instanceId | 删除任务实例 | 辅导员 |
| POST | /tasks/instances/assign | 分配任务 | 辅导员 |
| POST | /tasks/instances | 创建任务实例 | 辅导员 |
| POST | /tasks/instances/:instanceId/start | 开始执行任务 | 员工 |
| POST | /tasks/instances/:instanceId/pause | 暂停任务 | 员工 |
| POST | /tasks/instances/:instanceId/cancel | 取消任务 | 已认证 |
| POST | /tasks/instances/:instanceId/complete | 完成任务 | 员工 |
| POST | /tasks/instances/:instanceId/help | 请求帮助 | 员工 |
| POST | /tasks/steps/:executionId/start | 开始执行步骤 | 员工 |
| POST | /tasks/steps/:executionId/complete | 完成步骤 | 员工 |
| GET | /tasks/:taskId/executions | 获取任务执行记录（监控） | 已认证 |

#### 排班管理 (`/schedules`)

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | /schedules?date= | 获取某日排班列表 | 已认证 |
| GET | /schedules/week?startDate= | 获取一周排班概览 | 已认证 |
| POST | /schedules/batch | 批量排班 | 辅导员 |

#### 情绪管理 (`/emotions`)

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | /emotions/overview | 获取所有员工实时情绪概览 | 辅导员 |
| GET | /emotions/alerts | 获取预警列表 | 辅导员 |
| POST | /emotions/alerts/:alertId/handle | 处理预警 | 辅导员 |
| GET | /emotions/alert-rules | 获取预警规则列表 | 辅导员 |
| POST | /emotions/alert-rules | 创建预警规则 | 辅导员 |
| PUT | /emotions/alert-rules/:ruleId | 更新预警规则 | 辅导员 |
| DELETE | /emotions/alert-rules/:ruleId | 删除预警规则 | 辅导员 |
| GET | /emotions/today | 获取今日情绪记录 | 员工 |
| POST | /emotions/record | 记录情绪（员工自记录） | 员工 |
| POST | /emotions/:employeeId | 记录情绪（辅导员代记录） | 辅导员 |
| GET | /emotions/:employeeId | 获取情绪记录列表 | 可访问该员工 |
| GET | /emotions/:employeeId/stats | 获取情绪统计 | 可访问该员工 |

#### 沟通板 (`/communication`)

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | /communication/categories | 获取所有分类 | 公开/可选认证 |
| GET | /communication/categories/:categoryId | 获取分类详情（含常用语） | 公开/可选认证 |
| GET | /communication/search | 搜索常用语 | 公开/可选认证 |
| POST | /communication/categories | 创建分类 | 辅导员 |
| PUT | /communication/categories/:categoryId | 更新分类 | 辅导员 |
| DELETE | /communication/categories/:categoryId | 删除分类 | 辅导员 |
| GET | /communication/phrases | 获取所有常用语 | 已认证 |
| GET | /communication/categories/:categoryId/phrases | 获取分类下常用语 | 已认证 |
| POST | /communication/categories/:categoryId/phrases | 创建常用语 | 辅导员 |
| POST | /communication/categories/:categoryId/phrases/batch | 批量创建常用语 | 辅导员 |
| PUT | /communication/phrases/:phraseId | 更新常用语 | 辅导员 |
| DELETE | /communication/phrases/:phraseId | 删除常用语 | 辅导员 |

#### 消息通知 (`/notifications`)

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | /notifications | 获取通知列表 | 已认证 |
| POST | /notifications | 发送通知 | 已认证 |
| GET | /notifications/unread-count | 获取未读通知数量 | 已认证 |
| PUT | /notifications/read-all | 全部标记已读 | 已认证 |
| POST | /notifications/voice-cheer | 发送语音加油 | 已认证 |
| PUT | /notifications/:notificationId/read | 标记已读 | 已认证 |
| DELETE | /notifications/:notificationId | 删除通知 | 已认证 |

> 消息类型支持：`task_assigned`（任务分配）、`task_reminder`（任务提醒）、`emotion_alert`（情绪预警）、`voice_cheer`（语音鼓励）、`system`（系统通知）、`assist_request`（协助请求）、`assist_message`（协助消息）

#### 远程协助 (`/remote-assist`)

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| POST | /remote-assist/sessions | 创建协助请求（含照片上传） | 员工 |
| GET | /remote-assist/sessions/pending | 获取待接听协助列表 | 辅导员 |
| GET | /remote-assist/sessions | 获取协助会话列表 | 已认证 |
| GET | /remote-assist/sessions/:sessionId | 获取会话详情（含消息历史） | 已认证 |
| POST | /remote-assist/sessions/:sessionId/accept | 接听协助请求 | 辅导员 |
| POST | /remote-assist/sessions/:sessionId/messages | 发送消息（含文件上传） | 已认证 |
| GET | /remote-assist/sessions/:sessionId/messages | 获取会话消息历史 | 已认证 |
| POST | /remote-assist/sessions/:sessionId/annotation | 上传标注图片 | 辅导员 |
| POST | /remote-assist/sessions/:sessionId/end | 结束协助会话（可含评分） | 已认证 |

#### 数据统计 (`/statistics`)

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | /statistics/dashboard | 系统概览（仪表盘） | 辅导员 |
| GET | /statistics/task-completion?range= | 任务完成率统计 | 已认证 |
| GET | /statistics/step-duration?templateId=&range= | 步骤耗时分析（卡顿热点） | 已认证 |
| GET | /statistics/employee-overview?employeeId= | 员工工作概览 | 已认证 |
| GET | /statistics/emotion | 情绪统计数据 | 辅导员 |
| GET | /statistics/employee-work | 员工工作统计 | 辅导员 |

#### 设备管理 (`/devices`)

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| POST | /devices/bind-code | 生成绑定码 | 已认证 |
| POST | /devices/bind | 使用绑定码绑定设备 | 已认证 |
| GET | /devices | 获取当前用户设备列表 | 已认证 |
| POST | /devices/:bindingId/unbind | 解绑设备 | 已认证 |
| PUT | /devices/:deviceId/heartbeat | 设备心跳 | 已认证 |

---

## 数据库设计

### ER 关系概述

```
users (用户表)
  ├── employee_profiles (员工档案)     [1:1]
  ├── employee_groups (员工分组)       [N:1]
  ├── employee_counselor (员工-辅导员)  [N:M]
  ├── employee_parent (员工-家长)      [N:M]
  ├── task_templates (任务模板)         [1:N, 创建者]
  ├── task_instances (任务实例)         [1:N, 执行者]
  ├── emotion_records (情绪记录)        [1:N]
  ├── device_bindings (设备绑定)        [1:N]
  └── notifications (消息通知)          [1:N]

task_templates (任务模板)
  └── template_steps (模板步骤)         [1:N]

task_instances (任务实例)
  └── step_executions (步骤执行记录)    [1:N]

comm_categories (沟通板分类)
  └── comm_phrases (常用语)            [1:N]

emotion_alert_rules (情绪预警规则)
  └── 关联 employee_profiles            [N:1]

assist_sessions (远程协助会话)
  └── assist_messages (协助消息)       [1:N]
```

### 核心表清单（19 张表）

| 序号 | 表名 | 说明 |
|------|------|------|
| 1 | `users` | 用户表（5 种角色：counselor/co_counselor/parent/employee/employer） |
| 2 | `employee_profiles` | 员工档案（残疾类型、支持等级、工作场所等） |
| 3 | `employee_groups` | 员工分组（支持按组管理） |
| 4 | `employee_counselor` | 员工-辅导员关联（支持主/协辅导员） |
| 5 | `employee_parent` | 员工-家长关联（含审核状态） |
| 6 | `task_templates` | 任务模板（含分类、封面、预估时间） |
| 7 | `template_steps` | 模板步骤（含图片、音频、提示、预估时间） |
| 8 | `task_instances` | 任务实例（排班执行记录） |
| 9 | `step_executions` | 步骤执行记录（含耗时、尝试次数） |
| 10 | `emotion_records` | 情绪记录（6 种情绪类型、强度 1-5） |
| 11 | `emotion_alert_rules` | 情绪预警规则（连续天数、最低强度） |
| 12 | `comm_categories` | 沟通板分类 |
| 13 | `comm_phrases` | 沟通常用语（含图片、音频） |
| 14 | `notifications` | 消息通知（7 种消息类型） |
| 15 | `assist_sessions` | 远程协助会话（含评分） |
| 16 | `assist_messages` | 远程协助消息（文本/图片/标注/语音） |
| 17 | `emergency_records` | 应急记录 |
| 18 | `sync_queue` | 离线同步队列 |
| 19 | `device_bindings` | 设备绑定（绑定码激活机制） |

完整建表语句见 `server/database/init.sql`。

---

## 部署方案

### 开发环境

```bash
# 1. 启动 MySQL 和 Redis（Docker 方式）
docker run -d --name worknav-mysql -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD=password123 \
  -e MYSQL_DATABASE=worknav \
  mysql:8.0

docker run -d --name worknav-redis -p 6379:6379 redis:7-alpine

# 2. 启动后端
cd server && npm install && npm run dev

# 3. 启动辅导员端 Web
cd counselor-web && npm install && npm run dev

# 4. 构建并部署员工端 Web
cd employee-app && flutter pub get
flutter build web --release --base-href "/employee-app/"
cp -r build/web/* ../server/public/employee-app/

# 5. （可选）启动员工端移动端
flutter run
```

### 生产环境（国内云服务）

#### 推荐配置

| 资源 | 规格 | 说明 |
|------|------|------|
| ECS 服务器 | 4核 8GB | 运行 Node.js 服务 |
| RDS MySQL | 2核 4GB | 托管数据库 |
| Redis | 2GB | 托管缓存 |
| OSS | 按量付费 | 文件存储 |
| CDN | 按量付费 | 静态资源加速 |
| SSL 证书 | 免费版 | HTTPS |

#### 部署架构

```
用户请求 → CDN（静态资源）
         → Nginx（反向代理）
           → Node.js 服务（PM2 管理）
             → RDS MySQL
             → Redis
             → OSS（文件存储）
```

#### 部署步骤

**1. 服务器初始化**

```bash
# 安装 Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# 安装 PM2
sudo npm install -g pm2

# 安装 Nginx
sudo apt-get install -y nginx

# 安装 Flutter（仅构建员工端 Web 时需要）
sudo snap install flutter --classic
```

**2. 部署后端服务**

```bash
git clone https://github.com/gongwenqing314/worknav.git /opt/worknav
cd /opt/worknav/server

npm install --production
cp .env.example .env
vim .env  # 编辑生产环境配置

mysql -h your-rds-host -u root -p worknav < database/init.sql
mysql -h your-rds-host -u root -p worknav < migrations/seed.sql

pm2 start src/app.js --name worknav-server
pm2 save
pm2 startup
```

**3. 构建并部署员工端 Web**

```bash
cd /opt/worknav/employee-app
flutter pub get
flutter build web --release --base-href "/employee-app/"
cp -r build/web/* ../server/public/employee-app/
```

**4. 构建并部署辅导员端 Web**

```bash
cd /opt/worknav/counselor-web
npm install
npm run build
sudo cp -r dist/* /var/www/worknav/web/
```

**5. 配置 Nginx**

```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;

    # 辅导员端 Web（主站）
    location / {
        root /var/www/worknav/web;
        try_files $uri $uri/ /index.html;
    }

    # API 反向代理
    location /api/ {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # 员工端 Flutter Web（同源部署，由后端 Express 托管）
    location /employee-app/ {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
    }

    # WebSocket 代理
    location /socket.io/ {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
}
```

#### 监控与运维

```bash
pm2 monit          # PM2 进程监控
pm2 logs worknav-server  # 查看日志
tail -f /var/log/nginx/access.log  # Nginx 访问日志
```

---

## 使用指南

### 辅导员端使用流程

#### 首次使用

1. **注册账号**：访问辅导员端 Web，使用手机号注册
2. **创建员工**：进入「员工管理」→「添加员工」，填写员工信息
3. **配置设备**：在员工手机上安装 APP，完成设备绑定
4. **邀请家长**：在员工详情页生成邀请链接，发送给家长

#### 日常使用

1. **创建任务模板**：进入「任务管理」→「新建模板」，拆解任务步骤
2. **排班**：进入「排班管理」，选择日期和员工，分配任务
3. **监控进度**：在「任务监控」页面实时查看员工执行进度
4. **处理预警**：收到情绪预警通知后，及时介入支持
5. **远程协助**：收到协助请求后，在照片上标注并回传
6. **查看报表**：在「数据统计」页面查看工作表现趋势

### 员工端使用流程

#### 首次使用（辅导员引导）

1. 辅导员在员工手机上安装 APP（或打开 Web 版 `https://your-domain.com/employee-app/`）
2. 辅导员在 Web 端生成绑定码
3. 员工打开 APP，输入绑定码完成激活（Web 版自动设备登录）
4. 辅导员引导员工熟悉界面（任务/沟通板/情绪按钮）

#### 日常工作

1. **上班**：打开 APP，查看今日任务列表和统计面板
2. **执行任务**：点击任务 → 查看步骤图片 → 完成操作 → 点击绿色大勾
3. **需要帮助**：点击沟通板「我需要帮助」→ APP 自动语音播报
4. **表达情绪**：点击情绪卡片 → 选择当前感受
5. **遇到突发**：点击「拍照求助」→ 拍照发送给辅导员
6. **应急情况**：点击应急卡片 → 全屏展示给同事看

### 家长端使用流程

1. 辅导员发送邀请链接
2. 家长点击链接，注册账号并绑定孩子
3. 登录后查看孩子的工作概况：今日任务完成情况、情绪记录、预警通知
4. 可配置通知接收方式（APP 推送 / 短信）

---

## 离线模式说明

### 支持的离线功能

| 功能 | 离线可用 | 说明 |
|------|:---:|------|
| 查看今日任务 | ✅ | 需提前联网同步 |
| 执行任务步骤 | ✅ | 图片/视频需提前缓存 |
| 语音提示播放 | ✅ | 语音文件需提前缓存 |
| 沟通板常用语 | ✅ | 预录制音频缓存 |
| 情绪表达记录 | ✅ | 本地暂存 |
| 上下班/休息提醒 | ✅ | 基于本地时间 |
| 应急卡片展示 | ✅ | 纯本地功能 |
| 远程协助 | ❌ | 需网络 |
| 发送预警通知 | ❌ | 联网后自动补发 |

### 同步机制

1. **联网时**：自动下载当日及次日任务数据、沟通板配置、提醒规则
2. **断网时**：所有操作记录保存在本地 SQLite 数据库
3. **恢复网络**：自动上传本地暂存数据，补发预警通知，下载最新配置
4. **冲突处理**：采用"最后写入胜出"策略，服务端记录覆盖

---

## 无障碍设计说明

本产品面向心智障碍用户，无障碍设计是核心设计原则。

### 视觉无障碍

| 要素 | 规范 |
|------|------|
| 对比度 | 前景与背景 >= 4.5:1（WCAG AA） |
| 字体大小 | 标题 >= 24sp，正文 >= 20sp，按钮 >= 22sp |
| 按钮尺寸 | 主要操作按钮 >= 80x80dp |
| 图标尺寸 | 任务卡片图标 >= 120x120dp |
| 按钮间距 | >= 16dp |
| 色彩使用 | 不以颜色作为唯一信息传达方式 |

### 认知无障碍

| 要素 | 规范 |
|------|------|
| 页面复杂度 | 每页核心操作不超过 3 个 |
| 导航结构 | 固定底部导航，结构不变 |
| 信息呈现 | 每次只呈现一个步骤或一个决策 |
| 图标配文字 | 所有图标配文字标签 |
| 一致性 | 相同功能使用相同的图标、颜色和位置 |

### 听觉无障碍

| 要素 | 规范 |
|------|------|
| 语音+视觉 | 所有语音提示同时提供文字+动画反馈 |
| 语速调节 | 支持 0.8x / 1.0x / 1.2x 三档 |
| TTS 降级 | 预录制音频 → 系统 TTS → 视觉展示（三级降级） |

### 运动无障碍

| 要素 | 规范 |
|------|------|
| 按钮大小 | >= 80x80dp，易于点击 |
| 长按替代 | 所有长按操作提供点击确认替代方案 |
| 容错设计 | 关键操作需二次确认 |

---

## 安全设计

| 安全措施 | 说明 |
|----------|------|
| 数据传输 | TLS 1.2+ 加密 |
| 数据存储 | 敏感数据（手机号）加密存储 |
| 身份认证 | JWT + Refresh Token 双 Token 机制 |
| 设备登录 | 员工端 Web 通过设备 ID 自动登录，无需输入密码 |
| 权限控制 | RBAC 五角色权限矩阵 |
| 设备绑定 | 员工账号绑定设备，换机需辅导员授权 |
| 接口鉴权 | 所有 API 基于角色权限校验 |
| 数据隔离 | 不同辅导员数据严格隔离 |
| 操作日志 | 关键操作记录保留 180 天 |
| 隐私保护 | 员工情绪数据仅辅导员和家长可见 |
| 文件安全 | 上传文件内容安全审核 |

---

## 常见问题

### Q: 员工更换手机怎么办？

1. 员工在新手机上安装 APP，显示"请联系辅导员绑定新设备"
2. 辅导员在 Web 端「设备管理」页面生成 6 位绑定码（5 分钟有效）
3. 员工在新设备上输入绑定码，完成激活
4. 旧设备自动解绑

### Q: 员工端 Web 版和移动端有什么区别？

员工端 Web 版与移动端功能一致，采用 Flutter 同一套代码编译。Web 版通过同源部署在后端服务器上，无需安装 APP，适合在电脑或平板浏览器中使用。移动端支持离线模式和推送通知，Web 版暂不支持。

### Q: 语音播报没有声音怎么办？

系统采用三级降级策略：
1. 优先使用预录制音频文件
2. 预录制不可用时使用系统 TTS
3. TTS 不可用时显示放大文字 + 闪烁边框

检查：设置 → 语音播报开关是否开启 → 手机音量是否调至合适水平 → 手机是否安装了 TTS 引擎

### Q: 离线数据会丢失吗？

不会。离线期间所有操作保存在本地数据库，恢复网络后自动同步到服务器。

### Q: 辅导员如何查看员工卡在哪个步骤？

进入「数据统计」→「步骤耗时分析」，查看耗时超过标准 2 倍的步骤排行和卡顿员工列表。

### Q: 家长能看到哪些数据？

家长仅能查看自己孩子的数据：任务完成概况、情绪记录、预警通知。无法查看其他员工信息，也无法修改任何配置。

---

## 项目文档

| 文档 | 说明 |
|------|------|
| [需求文档（PRD）](docs/需求文档_PRD.md) | 完整的产品需求规格说明 |
| [设计方案](docs/设计方案.md) | 系统架构、技术选型、数据库设计 |
| [开发任务书](docs/开发任务书.md) | 开发阶段划分、任务拆解、工时估算 |

---

## 许可证

本项目为内部使用项目，未经授权不得外传。
