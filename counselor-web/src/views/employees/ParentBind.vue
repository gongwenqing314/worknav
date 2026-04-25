<template>
  <!-- 家长绑定管理页面 -->
  <div class="parent-bind-page page-container">
    <PageHeader :title="`家长绑定管理 - ${employeeName}`" :show-back="true">
      <template #actions>
        <el-button type="primary" :icon="Link" @click="showInviteDialog">生成邀请链接</el-button>
      </template>
    </PageHeader>

    <div class="card-container">
      <!-- 已绑定家长列表 -->
      <h3 class="section-title">已绑定家长</h3>
      <el-table :data="parentList" v-loading="loading" stripe>
        <el-table-column prop="name" label="家长姓名" width="120" />
        <el-table-column prop="phone" label="手机号" width="140" />
        <el-table-column prop="relation" label="关系" width="100" />
        <el-table-column prop="bindTime" label="绑定时间" width="180" />
        <el-table-column label="状态" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="row.status === 'active' ? 'success' : 'info'" size="small">
              {{ row.status === 'active' ? '已绑定' : '已解绑' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="100">
          <template #default="{ row }">
            <el-button
              v-if="row.status === 'active'"
              size="small"
              text
              type="danger"
              @click="handleUnbind(row)"
            >
              解绑
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- 邀请记录 -->
      <h3 class="section-title mt-lg">邀请记录</h3>
      <el-table :data="inviteList" stripe size="small">
        <el-table-column prop="code" label="邀请码" width="120" />
        <el-table-column prop="relation" label="关系" width="100" />
        <el-table-column prop="expiresAt" label="过期时间" width="180" />
        <el-table-column label="状态" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="row.used ? 'success' : 'warning'" size="small">
              {{ row.used ? '已使用' : '待使用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="usedByName" label="使用人" />
      </el-table>
    </div>

    <!-- 生成邀请链接对话框 -->
    <el-dialog v-model="inviteDialogVisible" title="生成家长邀请链接" width="480px">
      <el-form ref="inviteFormRef" :model="inviteForm" :rules="inviteRules" label-width="80px">
        <el-form-item label="关系" prop="relation">
          <el-select v-model="inviteForm.relation" placeholder="请选择关系">
            <el-option label="父亲" value="father" />
            <el-option label="母亲" value="mother" />
            <el-option label="其他监护人" value="other" />
          </el-select>
        </el-form-item>
        <el-form-item label="有效期" prop="expiresIn">
          <el-select v-model="inviteForm.expiresIn" placeholder="请选择有效期">
            <el-option label="24小时" :value="24" />
            <el-option label="7天" :value="168" />
            <el-option label="30天" :value="720" />
          </el-select>
        </el-form-item>
      </el-form>

      <!-- 生成的邀请信息 -->
      <div v-if="inviteInfo" class="invite-result">
        <el-alert type="success" :closable="false" show-icon>
          <template #title>邀请链接已生成</template>
        </el-alert>
        <div class="invite-link">
          <el-input :model-value="inviteInfo.link" readonly size="large">
            <template #append>
              <el-button @click="copyLink">复制</el-button>
            </template>
          </el-input>
        </div>
        <p class="invite-tip">请将此链接发送给家长，家长通过链接完成绑定。</p>
      </div>

      <template #footer>
        <el-button @click="inviteDialogVisible = false">关闭</el-button>
        <el-button v-if="!inviteInfo" type="primary" :loading="inviteLoading" @click="handleGenerateInvite">
          生成链接
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
/**
 * ParentBind - 家长绑定管理页面
 * 查看已绑定家长、生成邀请链接、解绑家长
 */
import { ref, reactive, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Link } from '@element-plus/icons-vue'
import PageHeader from '@/components/PageHeader.vue'
import { getParentBindings, generateParentInvite, unbindParent } from '@/api/user'
import { getEmployeeDetail } from '@/api/user'

const route = useRoute()
const employeeId = route.params.id
const employeeName = ref('')
const loading = ref(false)
const parentList = ref([])
const inviteList = ref([
  { code: 'INV20250115001', relation: '母亲', expiresAt: '2025-01-22 10:00', used: true, usedByName: '李妈妈' },
  { code: 'INV20250115002', relation: '父亲', expiresAt: '2025-01-22 10:00', used: false, usedByName: '' }
])

// 邀请对话框
const inviteDialogVisible = ref(false)
const inviteLoading = ref(false)
const inviteInfo = ref(null)
const inviteFormRef = ref(null)
const inviteForm = reactive({
  relation: '',
  expiresIn: 168
})
const inviteRules = {
  relation: [{ required: true, message: '请选择关系', trigger: 'change' }],
  expiresIn: [{ required: true, message: '请选择有效期', trigger: 'change' }]
}

async function fetchData() {
  loading.value = true
  try {
    const [empRes, parentRes] = await Promise.all([
      getEmployeeDetail(employeeId),
      getParentBindings(employeeId)
    ])
    employeeName.value = empRes.data?.name || ''
    parentList.value = parentRes.data || []
  } catch (error) {
    console.error('获取数据失败:', error)
  } finally {
    loading.value = false
  }
}

function showInviteDialog() {
  inviteInfo.value = null
  inviteForm.relation = ''
  inviteForm.expiresIn = 168
  inviteDialogVisible.value = true
}

async function handleGenerateInvite() {
  try {
    await inviteFormRef.value.validate()
  } catch { return }

  inviteLoading.value = true
  try {
    const res = await generateParentInvite(employeeId, inviteForm)
    inviteInfo.value = res.data || {
      link: `https://worknav.app/bind/${employeeId}?code=INV${Date.now()}`,
      code: `INV${Date.now()}`
    }
    ElMessage.success('邀请链接已生成')
  } catch (error) {
    console.error('生成邀请链接失败:', error)
  } finally {
    inviteLoading.value = false
  }
}

function copyLink() {
  if (inviteInfo.value?.link) {
    navigator.clipboard.writeText(inviteInfo.value.link).then(() => {
      ElMessage.success('链接已复制到剪贴板')
    }).catch(() => {
      ElMessage.warning('复制失败，请手动复制')
    })
  }
}

async function handleUnbind(row) {
  try {
    await ElMessageBox.confirm(`确定解绑家长 "${row.name}" 吗？`, '确认解绑', { type: 'warning' })
    await unbindParent(employeeId, row.id)
    ElMessage.success('解绑成功')
    fetchData()
  } catch (error) {
    if (error !== 'cancel') console.error('解绑失败:', error)
  }
}

onMounted(() => {
  fetchData()
})
</script>

<style scoped>
.section-title {
  font-size: 15px;
  font-weight: 600;
  color: #303133;
  margin: 0 0 12px;
}

.invite-result {
  margin-top: 16px;
}

.invite-link {
  margin-top: 12px;
}

.invite-tip {
  font-size: 12px;
  color: #909399;
  margin-top: 8px;
}
</style>
