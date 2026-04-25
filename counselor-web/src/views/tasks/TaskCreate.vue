<template>
  <!-- 创建/编辑任务页面 -->
  <div class="task-create-page page-container">
    <PageHeader :title="isEdit ? '编辑任务' : '创建任务'" :show-back="true">
      <template #actions>
        <el-button @click="$router.back()">取消</el-button>
        <el-button type="primary" :loading="saving" @click="handleSave">保存</el-button>
      </template>
    </PageHeader>

    <div class="task-form-layout">
      <!-- 左侧：基本信息 -->
      <div class="card-container form-section">
        <h3 class="section-title">基本信息</h3>
        <el-form ref="formRef" :model="formData" :rules="formRules" label-width="100px">
          <el-form-item label="任务名称" prop="title">
            <el-input v-model="formData.title" placeholder="请输入任务名称" maxlength="50" show-word-limit />
          </el-form-item>
          <el-form-item label="任务描述" prop="description">
            <el-input v-model="formData.description" type="textarea" :rows="3" placeholder="请描述任务内容" />
          </el-form-item>
          <el-form-item label="分配员工" prop="employeeIds">
            <el-select v-model="formData.employeeIds" multiple placeholder="请选择员工" style="width: 100%">
              <el-option v-for="emp in employeeOptions" :key="emp.id" :label="emp.name" :value="emp.id" />
            </el-select>
          </el-form-item>
          <el-form-item label="计划日期" prop="scheduledDate">
            <el-date-picker v-model="formData.scheduledDate" type="date" placeholder="选择日期" value-format="YYYY-MM-DD" />
          </el-form-item>
          <el-form-item label="优先级" prop="priority">
            <el-radio-group v-model="formData.priority">
              <el-radio value="low">低</el-radio>
              <el-radio value="medium">中</el-radio>
              <el-radio value="high">高</el-radio>
            </el-radio-group>
          </el-form-item>
          <el-form-item label="备注">
            <el-input v-model="formData.remark" type="textarea" :rows="2" placeholder="备注信息" />
          </el-form-item>
        </el-form>
      </div>

      <!-- 右侧：步骤编辑器 -->
      <div class="form-section">
        <div class="card-container">
          <h3 class="section-title">任务步骤</h3>
          <StepEditor v-model="formData.steps" />
        </div>

        <!-- 预览区域 -->
        <div class="card-container mt-md">
          <h3 class="section-title">步骤预览</h3>
          <div class="step-preview">
            <div v-for="(step, index) in formData.steps" :key="step.id" class="preview-step">
              <div class="preview-step__num">{{ index + 1 }}</div>
              <div class="preview-step__content">
                <div class="preview-step__title">
                  <el-tag v-if="step.isKey" type="danger" size="small" effect="dark">关键</el-tag>
                  {{ step.title || '未命名步骤' }}
                </div>
                <div v-if="step.description" class="preview-step__desc">{{ step.description }}</div>
                <div class="preview-step__media">
                  <el-image v-if="step.imageUrl" :src="step.imageUrl" fit="cover" style="width: 60px; height: 60px; border-radius: 4px;" />
                  <el-tag v-if="step.audioUrl" size="small" type="success">已录音</el-tag>
                  <el-tag v-if="step.videoUrl" size="small" type="warning">已上传视频</el-tag>
                </div>
              </div>
            </div>
            <el-empty v-if="formData.steps.length === 0" description="暂无步骤" :image-size="40" />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
/**
 * TaskCreate - 创建/编辑任务页面
 * 包含基本信息表单和步骤编辑器
 */
import { ref, reactive, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import PageHeader from '@/components/PageHeader.vue'
import StepEditor from '@/components/StepEditor.vue'
import { useTaskStore } from '@/stores/task'
import { getEmployeeList } from '@/api/user'
import { requiredRule, requiredSelectRule } from '@/utils/validators'

const route = useRoute()
const router = useRouter()
const taskStore = useTaskStore()
const isEdit = computed(() => !!route.params.id)
const saving = ref(false)
const formRef = ref(null)

const employeeOptions = ref([])

const formData = reactive({
  title: '',
  description: '',
  employeeIds: [],
  scheduledDate: '',
  priority: 'medium',
  remark: '',
  steps: []
})

const formRules = {
  title: [requiredRule('任务名称')],
  description: [requiredRule('任务描述')],
  employeeIds: [requiredSelectRule('员工')],
  scheduledDate: [requiredSelectRule('计划日期')]
}

async function fetchEmployees() {
  try {
    const res = await getEmployeeList({ page: 1, pageSize: 100, status: 'active' })
    employeeOptions.value = res.data?.list || res.data || []
  } catch (error) {
    console.error('获取员工列表失败:', error)
  }
}

async function fetchTaskDetail() {
  if (!isEdit.value) return
  try {
    const data = await taskStore.fetchTaskDetail(route.params.id)
    if (data) {
      Object.assign(formData, {
        title: data.title,
        description: data.description,
        employeeIds: data.employeeIds || [],
        scheduledDate: data.scheduledDate,
        priority: data.priority || 'medium',
        remark: data.remark || '',
        steps: data.steps || []
      })
    }
  } catch (error) {
    console.error('获取任务详情失败:', error)
  }
}

async function handleSave() {
  try {
    await formRef.value.validate()
  } catch { return }

  if (formData.steps.length === 0) {
    ElMessage.warning('请至少添加一个步骤')
    return
  }

  // 校验步骤标题
  const emptyStep = formData.steps.find(s => !s.title.trim())
  if (emptyStep) {
    ElMessage.warning('请填写所有步骤的标题')
    return
  }

  saving.value = true
  try {
    if (isEdit.value) {
      await taskStore.updateTask(route.params.id, formData)
      ElMessage.success('任务更新成功')
    } else {
      await taskStore.createTask(formData)
      ElMessage.success('任务创建成功')
    }
    router.push('/tasks')
  } catch (error) {
    console.error('保存失败:', error)
  } finally {
    saving.value = false
  }
}

onMounted(() => {
  fetchEmployees()
  fetchTaskDetail()
})
</script>

<style scoped>
.task-form-layout {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
  align-items: start;
}

.section-title {
  margin: 0 0 16px;
  font-size: 15px;
  font-weight: 600;
  color: #303133;
}

/* 步骤预览 */
.step-preview {
  max-height: 400px;
  overflow-y: auto;
}

.preview-step {
  display: flex;
  gap: 12px;
  padding: 10px 0;
  border-bottom: 1px solid #f0f0f0;
}

.preview-step:last-child {
  border-bottom: none;
}

.preview-step__num {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  background: #409EFF;
  color: #fff;
  font-size: 12px;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.preview-step__content {
  flex: 1;
  min-width: 0;
}

.preview-step__title {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 14px;
  color: #303133;
}

.preview-step__desc {
  font-size: 13px;
  color: #909399;
  margin-top: 2px;
}

.preview-step__media {
  display: flex;
  gap: 8px;
  margin-top: 6px;
  align-items: center;
}

@media screen and (max-width: 1024px) {
  .task-form-layout {
    grid-template-columns: 1fr;
  }
}
</style>
