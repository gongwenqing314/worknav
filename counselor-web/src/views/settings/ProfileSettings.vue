<template>
  <!-- 个人设置页面 -->
  <div class="profile-settings-page page-container">
    <PageHeader title="个人设置" />

    <div class="profile-layout">
      <!-- 个人信息 -->
      <div class="card-container profile-section">
        <h3 class="section-title">个人信息</h3>
        <div class="profile-avatar">
          <el-avatar :size="80" icon="UserFilled" />
          <el-button size="small" type="primary" plain>更换头像</el-button>
        </div>
        <el-form :model="profileForm" label-width="80px" class="mt-md">
          <el-form-item label="姓名">
            <el-input v-model="profileForm.name" />
          </el-form-item>
          <el-form-item label="手机号">
            <el-input v-model="profileForm.phone" disabled />
            <el-button type="primary" text size="small">修改</el-button>
          </el-form-item>
          <el-form-item label="角色">
            <el-tag>{{ ROLE_LABELS[profileForm.role] || profileForm.role }}</el-tag>
          </el-form-item>
          <el-form-item label="所属机构">
            <el-input v-model="profileForm.organization" disabled />
          </el-form-item>
        </el-form>
      </div>

      <!-- 修改密码 -->
      <div class="card-container profile-section">
        <h3 class="section-title">修改密码</h3>
        <el-form ref="passwordFormRef" :model="passwordForm" :rules="passwordRules" label-width="100px">
          <el-form-item label="当前密码" prop="oldPassword">
            <el-input v-model="passwordForm.oldPassword" type="password" show-password placeholder="请输入当前密码" />
          </el-form-item>
          <el-form-item label="新密码" prop="newPassword">
            <el-input v-model="passwordForm.newPassword" type="password" show-password placeholder="请输入新密码（至少6位，含字母和数字）" />
          </el-form-item>
          <el-form-item label="确认新密码" prop="confirmPassword">
            <el-input v-model="passwordForm.confirmPassword" type="password" show-password placeholder="请再次输入新密码" />
          </el-form-item>
          <el-form-item>
            <el-button type="primary" :loading="changingPassword" @click="handleChangePassword">修改密码</el-button>
          </el-form-item>
        </el-form>
      </div>

      <!-- 偏好设置 -->
      <div class="card-container profile-section">
        <h3 class="section-title">偏好设置</h3>
        <el-form label-width="100px">
          <el-form-item label="侧边栏折叠">
            <el-switch v-model="preferences.sidebarCollapsed" />
          </el-form-item>
          <el-form-item label="消息通知">
            <el-switch v-model="preferences.notifications" />
          </el-form-item>
          <el-form-item label="声音提醒">
            <el-switch v-model="preferences.sound" />
          </el-form-item>
        </el-form>
      </div>
    </div>

    <div class="save-bar">
      <el-button type="primary" :loading="saving" @click="handleSaveProfile">保存个人信息</el-button>
    </div>
  </div>
</template>

<script setup>
/**
 * ProfileSettings - 个人设置页面
 */
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import PageHeader from '@/components/PageHeader.vue'
import { useAuthStore } from '@/stores/auth'
import { changePassword } from '@/api/auth'
import { ROLE_LABELS } from '@/utils/constants'

const authStore = useAuthStore()
const saving = ref(false)
const changingPassword = ref(false)
const passwordFormRef = ref(null)

const profileForm = reactive({
  name: '',
  phone: '',
  role: '',
  organization: ''
})

const passwordForm = reactive({
  oldPassword: '',
  newPassword: '',
  confirmPassword: ''
})

const preferences = reactive({
  sidebarCollapsed: false,
  notifications: true,
  sound: true
})

const validateConfirm = (rule, value, callback) => {
  if (!value) callback(new Error('请再次输入新密码'))
  else if (value !== passwordForm.newPassword) callback(new Error('两次输入的密码不一致'))
  else callback()
}

const passwordRules = {
  oldPassword: [{ required: true, message: '请输入当前密码', trigger: 'blur' }],
  newPassword: [
    { required: true, message: '请输入新密码', trigger: 'blur' },
    { min: 6, message: '密码长度不能少于 6 位', trigger: 'blur' },
    { pattern: /^(?=.*[a-zA-Z])(?=.*\d)/, message: '密码需包含字母和数字', trigger: 'blur' }
  ],
  confirmPassword: [{ validator: validateConfirm, trigger: 'blur' }]
}

onMounted(() => {
  if (authStore.userInfo) {
    profileForm.name = authStore.userInfo.name || ''
    profileForm.phone = authStore.userInfo.phone || ''
    profileForm.role = authStore.userInfo.role || ''
    profileForm.organization = authStore.userInfo.organization || ''
  }
})

async function handleSaveProfile() {
  saving.value = true
  try {
    await new Promise(resolve => setTimeout(resolve, 500))
    ElMessage.success('个人信息已保存')
  } finally {
    saving.value = false
  }
}

async function handleChangePassword() {
  try {
    await passwordFormRef.value.validate()
  } catch { return }

  changingPassword.value = true
  try {
    await changePassword({
      oldPassword: passwordForm.oldPassword,
      newPassword: passwordForm.newPassword
    })
    ElMessage.success('密码修改成功，请重新登录')
    passwordForm.oldPassword = ''
    passwordForm.newPassword = ''
    passwordForm.confirmPassword = ''
  } catch (error) {
    console.error('修改密码失败:', error)
  } finally {
    changingPassword.value = false
  }
}
</script>

<style scoped>
.section-title {
  margin: 0 0 16px;
  font-size: 15px;
  font-weight: 600;
  color: #303133;
}

.profile-layout {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
  gap: 16px;
}

.profile-avatar {
  display: flex;
  align-items: center;
  gap: 16px;
}

.save-bar {
  margin-top: 24px;
  text-align: center;
}

@media screen and (max-width: 768px) {
  .profile-layout {
    grid-template-columns: 1fr;
  }
}
</style>
