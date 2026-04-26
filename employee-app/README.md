# 工作导航 - 员工端（Flutter）

> 工作导航（StepByStep）员工端应用，专为心智障碍人士设计。

## 概述

本应用是「工作导航」系统的员工端，支持 **iOS、Android 和 Web** 三个平台。通过视觉化任务引导、沟通辅助、情绪管理等功能，帮助心智障碍员工顺利完成日常工作。

## 功能模块

| 模块 | 说明 |
|------|------|
| 自动登录 | 设备绑定后自动登录，无需输入密码 |
| 今日任务 | 显示当日任务列表、统计面板（待完成/进行中/已完成） |
| 任务执行 | 逐步骤视觉化引导，大图片+文字说明+语音提示 |
| 沟通板 | 分类常用语，点击自动语音播报 |
| 情绪温度计 | 6 种情绪卡片，记录当前情绪状态 |
| 远程协助 | 拍照求助，实时接收辅导员标注反馈 |
| 提醒服务 | 上下班提醒、休息提醒 |
| 离线模式 | 断网时本地缓存，联网后自动同步 |

## 技术栈

- **框架**: Flutter 3.10+ / Dart 3.0+
- **状态管理**: Provider
- **网络请求**: dart:html HttpRequest（Web）/ Dio（移动端）
- **本地存储**: SharedPreferences + SQLite
- **音频播放**: just_audio
- **语音合成**: flutter_tts（降级方案）

## 项目结构

```
lib/
├── main.dart                # 应用入口（初始化全局服务）
├── app.dart                 # MaterialApp 配置（主题、路由）
├── core/                    # 核心层
│   ├── constants/           # API 地址、存储键名常量
│   ├── network/             # DioClient、SyncService
│   ├── theme/               # AppTheme（高对比度无障碍主题）
│   └── utils/               # StorageUtil、AudioPlayer
├── features/                # 功能模块
│   ├── auth/                # 启动页、设备自动登录
│   ├── home/                # 主页、今日任务列表
│   ├── task/                # 任务执行、步骤引导
│   ├── communication/       # 沟通板
│   ├── emotion/             # 情绪温度计
│   ├── remote_assist/       # 远程协助
│   ├── reminders/           # 提醒服务
│   └── settings/            # 设置
└── shared/                  # 共享层
    ├── models/              # 数据模型（TaskInstance 等）
    ├── services/            # 业务服务（AuthService、TaskService 等）
    └── widgets/             # 通用 UI 组件
```

## 快速开始

### 环境要求

- Flutter SDK >= 3.10.0
- Dart SDK >= 3.0.0
- Xcode >= 15.0（iOS 构建，仅 macOS）
- Android SDK >= 33（Android 构建）
- Chrome 最新版（Web 调试）

### 安装依赖

```bash
flutter pub get
```

### 配置 API 地址

编辑 `lib/core/constants/api_constants.dart`：

```dart
// 移动端：根据设备类型选择
static const String baseUrl = 'http://10.0.2.2:3000/api/v1'; // Android 模拟器
// static const String baseUrl = 'http://localhost:3000/api/v1'; // iOS 模拟器

// Web 版：自动使用相对路径 /api/v1（同源部署），无需配置
```

### 运行

```bash
# 移动端
flutter run

# Web 调试
flutter run -d chrome
```

### 构建

```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release

# Web（同源部署）
flutter build web --release --base-href "/employee-app/"
```

## Flutter Web 说明

员工端支持 Flutter Web 编译，采用**同源部署**方案：

- 构建产物部署在后端 `/employee-app/` 路径下
- 由 Express 静态文件服务直接托管
- API 请求使用相对路径，不存在 CORS 跨域问题
- Web 版使用 `dart:html` 的 `HttpRequest` 替代 Dio（Dio 在 Web 上存在兼容性问题）

### 已知的 Web 平台限制

- 本地通知不可用（Web 模式）
- 离线 SQLite 不可用（Web 模式使用 localStorage 缓存）
- 推送通知不可用
- SharedPreferences 值为 JSON 编码格式，读取时需 `jsonDecode`

## 无障碍设计

本应用面向心智障碍用户，遵循以下无障碍设计原则：

- **高对比度主题**：前景与背景对比度 >= 4.5:1
- **大字体**：标题 >= 24sp，正文 >= 20sp
- **大按钮**：主要操作按钮 >= 80x80dp
- **简洁导航**：固定底部 5 个标签（任务/沟通板/情绪/求助/设置）
- **图标配文字**：所有图标均有文字标签
- **文字缩放限制**：1.0x ~ 1.5x 范围
