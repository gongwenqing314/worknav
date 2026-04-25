<template>
  <!-- 登录页面 -->
  <div class="login-page">
    <div class="login-container">
      <!-- 左侧品牌区域 -->
      <div class="login-brand">
        <div class="brand-content">
          <el-icon :size="48" color="#409EFF"><Location /></el-icon>
          <h1 class="brand-title">工作导航</h1>
          <p class="brand-subtitle">StepByStep</p>
          <p class="brand-desc">为心智障碍人士提供工作支持的专业管理平台</p>
        </div>
      </div>

      <!-- 右侧登录表单 -->
      <div class="login-form-wrapper">
        <div class="login-form-container">
          <h2 class="form-title">辅导员登录</h2>

          <!-- 登录方式切换 -->
          <el-tabs v-model="loginType" class="login-tabs">
            <el-tab-pane label="密码登录" name="password" />
            <el-tab-pane label="验证码登录" name="sms" />
          </el-tabs>

          <el-form
            ref="loginFormRef"
            :model="loginForm"
            :rules="loginRules"
            size="large"
            @submit.prevent="handleLogin"
          >
            <!-- 手机号 -->
            <el-form-item prop="phone">
              <el-input
                v-model="loginForm.phone"
                placeholder="请输入手机号"
                :prefix-icon="Iphone"
                maxlength="11"
              />
            </el-form-item>

            <!-- 密码（密码登录时显示） -->
            <el-form-item v-if="loginType === 'password'" prop="password">
              <el-input
                v-model="loginForm.password"
                type="password"
                placeholder="请输入密码"
                :prefix-icon="Lock"
                show-password
                @keyup.enter="handleLogin"
              />
            </el-form-item>

            <!-- 验证码（验证码登录时显示） -->
            <el-form-item v-if="loginType === 'sms'" prop="code">
              <div class="sms-input">
                <el-input
                  v-model="loginForm.code"
                  placeholder="请输入验证码"
                  :prefix-icon="Message"
                  maxlength="6"
                  @keyup.enter="handleLogin"
                />
                <el-button
                  :disabled="smsCooldown > 0"
                  @click="handleSendSms"
                  class="sms-btn"
                >
                  {{ smsCooldown > 0 ? `${smsCooldown}s 后重发` : '获取验证码' }}
                </el-button>
              </div>
            </el-form-item>

            <!-- 登录按钮 -->
            <el-form-item>
              <el-button
                type="primary"
                :loading="loading"
                class="login-btn"
                @click="handleLogin"
              >
                {{ loading ? '登录中...' : '登 录' }}
              </el-button>
            </el-form-item>
          </el-form>

          <!-- 底部链接 -->
          <div class="login-footer">
            <span>还没有账号？</span>
            <router-link to="/register">立即注册</router-link>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
/**
 * LoginView - 登录页面
 * 支持手机号+密码登录和手机号+验证码登录
 */
import { ref, reactive } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Iphone, Lock, Message, Location } from '@element-plus/icons-vue'
import { useAuthStore } from '@/stores/auth'
import { sendSmsCode } from '@/api/auth'
import { phoneRule, smsCodeRule, requiredRule } from '@/utils/validators'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()

// 登录方式
const loginType = ref('password')
// 加载状态
const loading = ref(false)
// 验证码倒计时
const smsCooldown = ref(0)
// 表单引用
const loginFormRef = ref(null)

// 登录表单数据
const loginForm = reactive({
  phone: '',
  password: '',
  code: ''
})

// 表单校验规则
const loginRules = {
  phone: [phoneRule],
  password: [requiredRule('密码')],
  code: [smsCodeRule]
}

/**
 * 发送验证码
 */
async function handleSendSms() {
  // 先校验手机号
  try {
    await loginFormRef.value.validateField('phone')
  } catch {
    return
  }

  try {
    await sendSmsCode(loginForm.phone)
    ElMessage.success('验证码已发送')
    // 开始倒计时 60 秒
    smsCooldown.value = 60
    const timer = setInterval(() => {
      smsCooldown.value--
      if (smsCooldown.value <= 0) {
        clearInterval(timer)
      }
    }, 1000)
  } catch (error) {
    console.error('发送验证码失败:', error)
  }
}

/**
 * 登录
 */
async function handleLogin() {
  try {
    await loginFormRef.value.validate()
  } catch {
    return
  }

  loading.value = true
  try {
    if (loginType.value === 'password') {
      await authStore.loginByPasswordAction({
        phone: loginForm.phone,
        password: loginForm.password
      })
    } else {
      await authStore.loginBySmsAction({
        phone: loginForm.phone,
        code: loginForm.code
      })
    }
    ElMessage.success('登录成功')
    // 跳转到之前的页面或首页
    const redirect = route.query.redirect || '/'
    router.push(redirect)
  } catch (error) {
    console.error('登录失败:', error)
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 20px;
}

.login-container {
  display: flex;
  width: 900px;
  max-width: 100%;
  min-height: 520px;
  background: #fff;
  border-radius: 16px;
  overflow: hidden;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
}

/* ===== 左侧品牌 ===== */
.login-brand {
  width: 380px;
  background: linear-gradient(135deg, #409EFF 0%, #337ecc 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 40px;
  flex-shrink: 0;
}

.brand-content {
  text-align: center;
  color: #fff;
}

.brand-title {
  font-size: 32px;
  font-weight: 700;
  margin: 16px 0 4px;
}

.brand-subtitle {
  font-size: 16px;
  opacity: 0.9;
  margin-bottom: 16px;
}

.brand-desc {
  font-size: 14px;
  opacity: 0.8;
  line-height: 1.6;
}

/* ===== 右侧表单 ===== */
.login-form-wrapper {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 40px;
}

.login-form-container {
  width: 100%;
  max-width: 360px;
}

.form-title {
  font-size: 24px;
  font-weight: 600;
  color: #303133;
  margin-bottom: 24px;
}

.login-tabs {
  margin-bottom: 24px;
}

.login-tabs :deep(.el-tabs__item) {
  font-size: 15px;
}

/* 验证码输入框 */
.sms-input {
  display: flex;
  gap: 12px;
  width: 100%;
}

.sms-input .el-input {
  flex: 1;
}

.sms-btn {
  white-space: nowrap;
  min-width: 120px;
}

/* 登录按钮 */
.login-btn {
  width: 100%;
  height: 44px;
  font-size: 16px;
}

/* 底部链接 */
.login-footer {
  text-align: center;
  font-size: 14px;
  color: #909399;
  margin-top: 16px;
}

.login-footer a {
  color: #409EFF;
  margin-left: 4px;
}

/* ===== 响应式 ===== */
@media screen and (max-width: 768px) {
  .login-brand {
    display: none;
  }

  .login-container {
    min-height: auto;
  }

  .login-form-wrapper {
    padding: 32px 24px;
  }
}
</style>
