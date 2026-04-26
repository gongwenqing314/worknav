<template>
  <!-- 预警规则配置页面 -->
  <div class="alert-rules-page page-container">
    <PageHeader title="预警规则配置" :show-back="true">
      <template #actions>
        <el-button type="primary" :icon="Plus" @click="handleAdd">新增规则</el-button>
      </template>
    </PageHeader>

    <div class="card-container">
      <el-table :data="rules" v-loading="loading" stripe>
        <el-table-column prop="name" label="规则名称" min-width="160" show-overflow-tooltip />
        <el-table-column label="触发情绪" min-width="180">
          <template #default="{ row }">
            <el-tag
              v-for="emo in row.negativeTypes"
              :key="emo"
              :type="getEmotionTagType(emo)"
              size="small"
              style="margin-right: 4px"
            >
              {{ EMOTION_LABELS[emo] || emo }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="连续天数" width="100" align="center">
          <template #default="{ row }">{{ row.consecutiveDays }}天</template>
        </el-table-column>
        <el-table-column label="最低强度" width="100" align="center">
          <template #default="{ row }">≥ {{ row.minIntensity }}</template>
        </el-table-column>
        <el-table-column label="通知辅导员" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="row.notifyCounselor ? 'success' : 'info'" size="small">
              {{ row.notifyCounselor ? '是' : '否' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="通知家长" width="90" align="center">
          <template #default="{ row }">
            <el-tag :type="row.notifyParent ? 'success' : 'info'" size="small">
              {{ row.notifyParent ? '是' : '否' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="createdAt" label="创建时间" width="170" />
        <el-table-column label="状态" width="80" align="center">
          <template #default="{ row }">
            <el-tag :type="row.isActive ? 'success' : 'info'" size="small">
              {{ row.isActive ? '启用' : '停用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="140" fixed="right">
          <template #default="{ row }">
            <el-button size="small" text type="primary" @click="handleEdit(row)">编辑</el-button>
            <el-button size="small" text type="danger" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 编辑对话框 -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="500px">
      <el-form ref="formRef" :model="formData" :rules="formRules" label-width="110px">
        <el-form-item label="规则名称" prop="name">
          <el-input v-model="formData.name" placeholder="如：焦虑持续预警" />
        </el-form-item>
        <el-form-item label="触发情绪" prop="negativeTypes">
          <el-select v-model="formData.negativeTypes" multiple placeholder="选择消极情绪类型" style="width: 100%">
            <el-option label="焦虑" value="anxious" />
            <el-option label="悲伤" value="sad" />
            <el-option label="愤怒" value="angry" />
            <el-option label="困惑" value="confused" />
          </el-select>
        </el-form-item>
        <el-form-item label="连续天数" prop="consecutiveDays">
          <el-input-number v-model="formData.consecutiveDays" :min="1" :max="30" />
          <span class="form-tip">天（连续出现触发预警）</span>
        </el-form-item>
        <el-form-item label="最低强度" prop="minIntensity">
          <el-input-number v-model="formData.minIntensity" :min="1" :max="5" />
          <span class="form-tip">（情绪强度≥此值触发）</span>
        </el-form-item>
        <el-form-item label="通知辅导员">
          <el-switch v-model="formData.notifyCounselor" />
        </el-form-item>
        <el-form-item label="通知家长">
          <el-switch v-model="formData.notifyParent" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSave">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
/**
 * AlertRules - 预警规则配置页面
 */
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import PageHeader from '@/components/PageHeader.vue'
import { getAlertRules, createAlertRule, updateAlertRule, deleteAlertRule } from '@/api/emotion'
import { EMOTION_LABELS, EMOTION_COLORS } from '@/utils/constants'

const loading = ref(false)
const rules = ref([])
const dialogVisible = ref(false)
const dialogTitle = ref('新增规则')
const editingId = ref(null)
const formRef = ref(null)

const formData = reactive({
  name: '',
  negativeTypes: [],
  consecutiveDays: 2,
  minIntensity: 3,
  notifyCounselor: true,
  notifyParent: false,
})
const formRules = {
  name: [{ required: true, message: '请输入规则名称', trigger: 'blur' }],
  negativeTypes: [{ required: true, type: 'array', min: 1, message: '请选择至少一种情绪', trigger: 'change' }],
  consecutiveDays: [{ required: true, message: '请输入连续天数', trigger: 'blur' }],
  minIntensity: [{ required: true, message: '请输入最低强度', trigger: 'blur' }],
}

function getEmotionTagType(emotion) {
  const map = { happy: 'success', calm: '', anxious: 'warning', angry: 'danger', sad: 'info', confused: 'warning' }
  return map[emotion] || 'info'
}

async function fetchData() {
  loading.value = true
  try {
    const res = await getAlertRules()
    const list = Array.isArray(res.data) ? res.data : []
    // 后端下划线字段 → 前端驼峰字段
    rules.value = list.map(r => ({
      id: r.id,
      name: r.name || '',
      employeeId: r.employee_id,
      negativeTypes: r.negative_types || [],
      consecutiveDays: r.consecutive_days || 3,
      minIntensity: r.min_intensity || 3,
      notifyCounselor: !!r.notify_counselor,
      notifyParent: !!r.notify_parent,
      isActive: !!r.is_active,
      createdAt: r.created_at || '',
    }))
  } catch (error) {
    console.error('获取预警规则失败:', error)
    rules.value = []
  } finally {
    loading.value = false
  }
}

function handleAdd() {
  editingId.value = null
  dialogTitle.value = '新增规则'
  Object.assign(formData, { name: '', negativeTypes: [], consecutiveDays: 2, minIntensity: 3, notifyCounselor: true, notifyParent: false })
  dialogVisible.value = true
}

function handleEdit(row) {
  editingId.value = row.id
  dialogTitle.value = '编辑规则'
  Object.assign(formData, row)
  dialogVisible.value = true
}

async function handleSave() {
  try { await formRef.value.validate() } catch { return }
  try {
    // 前端驼峰 → 后端下划线
    const payload = {
      name: formData.name,
      negativeTypes: formData.negativeTypes,
      consecutiveDays: formData.consecutiveDays,
      minIntensity: formData.minIntensity,
      notifyCounselor: formData.notifyCounselor ? 1 : 0,
      notifyParent: formData.notifyParent ? 1 : 0,
    }
    if (editingId.value) {
      await updateAlertRule(editingId.value, payload)
      ElMessage.success('更新成功')
    } else {
      await createAlertRule(payload)
      ElMessage.success('创建成功')
    }
    dialogVisible.value = false
    fetchData()
  } catch (error) { console.error('保存失败:', error) }
}

async function handleDelete(row) {
  try {
    await ElMessageBox.confirm(`确定删除规则 "${row.name}" 吗？`, '确认', { type: 'warning' })
    await deleteAlertRule(row.id)
    ElMessage.success('删除成功')
    fetchData()
  } catch (error) { if (error !== 'cancel') console.error(error) }
}

onMounted(() => { fetchData() })
</script>

<style scoped>
.form-tip {
  font-size: 12px;
  color: #909399;
  margin-left: 8px;
}
</style>
