<template>
  <!-- 注册页面 -->
  <div class="register-page">
    <div class="register-container">
      <!-- 品牌区域 -->
      <div class="register-brand">
        <el-icon :size="40" color="#409EFF"><Location /></el-icon>
        <h1>工作导航</h1>
        <p>StepByStep - 辅导员注册</p>
      </div>

      <!-- 注册表单 -->
      <div class="register-form-wrapper">
        <el-form
          ref="registerFormRef"
          :model="registerForm"
          :rules="registerRules"
          label-width="80px"
          size="large"
        >
          <el-form-item label="姓名" prop="name">
            <el-input v-model="registerForm.name" placeholder="请输入真实姓名" />
          </el-form-item>

          <el-form-item label="手机号" prop="phone">
            <el-input v-model="registerForm.phone" placeholder="请输入手机号" maxlength="11" />
          </el-form-item>

          <el-form-item label="验证码" prop="code">
            <div class="sms-input">
              <el-input v-model="registerForm.code" placeholder="请输入验证码" maxlength="6" />
              <el-button :disabled="smsCooldown > 0" @click="handleSendSms">
                {{ smsCooldown > 0 ? `${smsCooldown}s` : '获取验证码' }}
              </el-button>
            </div>
          </el-form-item>

          <el-form-item label="密码" prop="password">
            <el-input v-model="registerForm.password" type="password" placeholder="请设置密码（至少6位，含字母和数字）" show-password />
          </el-form-item>

          <el-form-item label="确认密码" prop="confirmPassword">
            <el-input v-model="registerForm.confirmPassword" type="password" placeholder="请再次输入密码" show-password />
          </el-form-item>

          <el-form-item label="所属机构" prop="organization">
            <el-input v-model="registerForm.organization" placeholder="请输入所属机构名称" />
          </el-form-item>

          <el-form-item>
            <el-button type="primary" :loading="loading" class="register-btn" @click="handleRegister">
              {{ loading ? '注册中...' : '立即注册' }}
            </el-button>
          </el-form-item>

          <div class="form-footer">
            <span>已有账号？</span>
            <router-link to="/login">返回登录</router-link>
          </div>
        </el-form>
      </div>
    </div>
  </div>
</template>

<script setup>
/**
 * RegisterView - 注册页面
 * 辅导员注册表单
 */
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Location } from '@element-plus/icons-vue'
import { register, sendSmsCode } from '@/api/auth'
import { phoneRule, smsCodeRule, requiredRule } from '@/utils/validators'

const router = useRouter()
const loading = ref(false)
const smsCooldown = ref(0)
const registerFormRef = ref(null)

const registerForm = reactive({
  name: '',
  phone: '',
  code: '',
  password: '',
  confirmPassword: '',
  organization: ''
})

// 确认密码校验
const validateConfirm = (rule, value, callback) => {
  if (!value) {
    callback(new Error('请再次输入密码'))
  } else if (value !== registerForm.password) {
    callback(new Error('两次输入的密码不一致'))
  } else {
    callback()
  }
}

const registerRules = {
  name: [requiredRule('姓名')],
  phone: [phoneRule],
  code: [smsCodeRule],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, message: '密码长度不能少于 6 位', trigger: 'blur' },
    { pattern: /^(?=.*[a-zA-Z])(?=.*\d)/, message: '密码需包含字母和数字', trigger: 'blur' }
  ],
  confirmPassword: [{ validator: validateConfirm, trigger: 'blur' }],
  organization: [requiredRule('所属机构')]
}

/**
 * 发送验证码
 */
async function handleSendSms() {
  try {
    await registerFormRef.value.validateField('phone')
  } catch {
    return
  }
  try {
    await sendSmsCode(registerForm.phone)
    ElMessage.success('验证码已发送')
    smsCooldown.value = 60
    const timer = setInterval(() => {
      smsCooldown.value--
      if (smsCooldown.value <= 0) clearInterval(timer)
    }, 1000)
  } catch (error) {
    console.error('发送验证码失败:', error)
  }
}

/**
 * 注册
 */
async function handleRegister() {
  try {
    await registerFormRef.value.validate()
  } catch {
    return
  }

  loading.value = true
  try {
    await register({
      name: registerForm.name,
      phone: registerForm.phone,
      code: registerForm.code,
      password: registerForm.password,
      organization: registerForm.organization
    })
    ElMessage.success('注册成功，请登录')
    router.push('/login')
  } catch (error) {
    console.error('注册失败:', error)
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.register-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 20px;
}

.register-container {
  width: 560px;
  max-width: 100%;
  background: #fff;
  border-radius: 16px;
  overflow: hidden;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
}

.register-brand {
  text-align: center;
  padding: 32px 20px 16px;
}

.register-brand h1 {
  font-size: 24px;
  color: #303133;
  margin: 8px 0 4px;
}

.register-brand p {
  color: #909399;
  font-size: 14px;
}

.register-form-wrapper {
  padding: 16px 40px 40px;
}

.sms-input {
  display: flex;
  gap: 12px;
  width: 100%;
}

.sms-input .el-input {
  flex: 1;
}

.register-btn {
  width: 100%;
  height: 44px;
  font-size: 16px;
}

.form-footer {
  text-align: center;
  font-size: 14px;
  color: #909399;
}

.form-footer a {
  color: #409EFF;
  margin-left: 4px;
}

@media screen and (max-width: 768px) {
  .register-form-wrapper {
    padding: 16px 20px 32px;
  }
}
</style>
