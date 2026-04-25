<template>
  <!-- 设备管理页面 -->
  <div class="device-manage-page page-container">
    <PageHeader title="设备管理">
      <template #actions>
        <el-button type="primary" :icon="Plus" @click="showBindDialog">生成绑定码</el-button>
      </template>
    </PageHeader>

    <!-- 设备管理组件 -->
    <DeviceManager />

    <!-- 生成绑定码对话框 -->
    <el-dialog v-model="bindDialogVisible" title="生成设备绑定码" width="440px">
      <el-form :model="bindForm" label-width="80px">
        <el-form-item label="绑定员工">
          <el-select v-model="bindForm.employeeId" placeholder="选择员工" style="width: 100%">
            <el-option v-for="emp in employeeOptions" :key="emp.id" :label="emp.name" :value="emp.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="有效期">
          <el-select v-model="bindForm.expiresIn" style="width: 100%">
            <el-option label="24小时" :value="24" />
            <el-option label="7天" :value="168" />
            <el-option label="30天" :value="720" />
          </el-select>
        </el-form-item>
      </el-form>

      <div v-if="bindCode" class="bind-code-result">
        <el-alert type="success" :closable="false" show-icon>
          <template #title>绑定码已生成</template>
        </el-alert>
        <div class="bind-code-display">
          <div class="code-value">{{ bindCode }}</div>
          <el-button type="primary" @click="copyCode">复制绑定码</el-button>
        </div>
        <p class="bind-tip">请在员工设备上输入此绑定码完成绑定。</p>
      </div>

      <template #footer>
        <el-button @click="bindDialogVisible = false">关闭</el-button>
        <el-button v-if="!bindCode" type="primary" :loading="generating" @click="handleGenerate">生成绑定码</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
/**
 * DeviceManage - 设备管理页面
 */
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import PageHeader from '@/components/PageHeader.vue'
import DeviceManager from '@/components/DeviceManager.vue'
import { generateBindCode } from '@/api/device'
import { getEmployeeList } from '@/api/user'

const employeeOptions = ref([])
const bindDialogVisible = ref(false)
const generating = ref(false)
const bindCode = ref('')
const bindForm = reactive({ employeeId: '', expiresIn: 24 })

async function fetchEmployees() {
  try {
    const res = await getEmployeeList({ page: 1, pageSize: 100, status: 'active' })
    employeeOptions.value = res.data?.list || []
  } catch (error) { console.error(error) }
}

function showBindDialog() {
  bindCode.value = ''
  bindForm.employeeId = ''
  bindForm.expiresIn = 24
  bindDialogVisible.value = true
}

async function handleGenerate() {
  if (!bindForm.employeeId) {
    ElMessage.warning('请选择员工')
    return
  }
  generating.value = true
  try {
    const res = await generateBindCode(bindForm)
    bindCode.value = res.data?.code || `BIND-${Date.now().toString(36).toUpperCase()}`
    ElMessage.success('绑定码已生成')
  } catch (error) {
    console.error('生成绑定码失败:', error)
  } finally {
    generating.value = false
  }
}

function copyCode() {
  navigator.clipboard.writeText(bindCode.value).then(() => {
    ElMessage.success('已复制到剪贴板')
  }).catch(() => {
    ElMessage.warning('复制失败')
  })
}

onMounted(() => { fetchEmployees() })
</script>

<style scoped>
.bind-code-result {
  margin-top: 16px;
}

.bind-code-display {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-top: 12px;
}

.code-value {
  flex: 1;
  font-size: 24px;
  font-weight: 700;
  font-family: 'Courier New', monospace;
  color: #303133;
  background: #f5f7fa;
  padding: 12px 16px;
  border-radius: 8px;
  text-align: center;
  letter-spacing: 4px;
}

.bind-tip {
  font-size: 12px;
  color: #909399;
  margin-top: 8px;
}
</style>
