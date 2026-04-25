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
        <el-table-column prop="name" label="规则名称" min-width="140" />
        <el-table-column label="触发情绪" width="100">
          <template #default="{ row }">
            <el-tag :type="getEmotionTagType(row.emotion)" size="small">
              {{ EMOTION_LABELS[row.emotion] || row.emotion }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="持续时间" width="120" align="center">
          <template #default="{ row }">{{ row.duration }}分钟</template>
        </el-table-column>
        <el-table-column label="通知辅导员" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="row.notifyCounselors ? 'success' : 'info'" size="small">
              {{ row.notifyCounselors ? '是' : '否' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="createdAt" label="创建时间" width="170" />
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
      <el-form ref="formRef" :model="formData" :rules="formRules" label-width="100px">
        <el-form-item label="规则名称" prop="name">
          <el-input v-model="formData.name" placeholder="如：焦虑持续预警" />
        </el-form-item>
        <el-form-item label="触发情绪" prop="emotion">
          <el-select v-model="formData.emotion" placeholder="选择情绪类型">
            <el-option v-for="(label, key) in EMOTION_LABELS" :key="key" :label="label" :value="key" />
          </el-select>
        </el-form-item>
        <el-form-item label="持续时间" prop="duration">
          <el-input-number v-model="formData.duration" :min="1" :max="120" />
          <span class="form-tip">分钟（超过此时长触发预警）</span>
        </el-form-item>
        <el-form-item label="通知辅导员">
          <el-switch v-model="formData.notifyCounselors" />
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

const formData = reactive({ name: '', emotion: '', duration: 30, notifyCounselors: true })
const formRules = {
  name: [{ required: true, message: '请输入规则名称', trigger: 'blur' }],
  emotion: [{ required: true, message: '请选择情绪类型', trigger: 'change' }],
  duration: [{ required: true, message: '请输入持续时间', trigger: 'blur' }]
}

function getEmotionTagType(emotion) {
  const map = { happy: 'success', calm: '', anxious: 'warning', angry: 'danger', sad: 'info', confused: 'warning' }
  return map[emotion] || 'info'
}

async function fetchData() {
  loading.value = true
  try {
    const res = await getAlertRules()
    rules.value = res.data || []
  } catch (error) {
    rules.value = [
      { id: '1', name: '焦虑持续预警', emotion: 'anxious', duration: 30, notifyCounselors: true, createdAt: '2025-01-10' },
      { id: '2', name: '愤怒预警', emotion: 'angry', duration: 10, notifyCounselors: true, createdAt: '2025-01-08' },
      { id: '3', name: '悲伤持续预警', emotion: 'sad', duration: 60, notifyCounselors: false, createdAt: '2025-01-05' }
    ]
  } finally {
    loading.value = false
  }
}

function handleAdd() {
  editingId.value = null
  dialogTitle.value = '新增规则'
  Object.assign(formData, { name: '', emotion: '', duration: 30, notifyCounselors: true })
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
    if (editingId.value) {
      await updateAlertRule(editingId.value, formData)
      ElMessage.success('更新成功')
    } else {
      await createAlertRule(formData)
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
