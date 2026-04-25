<template>
  <!-- 任务模板管理页面 -->
  <div class="template-list-page page-container">
    <PageHeader title="任务模板管理">
      <template #actions>
        <el-button type="primary" :icon="Plus" @click="handleCreate">创建模板</el-button>
      </template>
    </PageHeader>

    <div class="card-container">
      <div class="search-bar">
        <el-input v-model="keyword" placeholder="搜索模板名称" clearable style="width: 240px" @clear="fetchData" @keyup.enter="fetchData" />
        <el-select v-model="category" placeholder="分类" clearable style="width: 140px" @change="fetchData">
          <el-option label="清洁" value="cleaning" />
          <el-option label="整理" value="organizing" />
          <el-option label="搬运" value="transport" />
          <el-option label="包装" value="packaging" />
          <el-option label="其他" value="other" />
        </el-select>
        <el-button :icon="Search" @click="fetchData">搜索</el-button>
      </div>

      <el-table :data="templateList" v-loading="loading" stripe>
        <el-table-column prop="name" label="模板名称" min-width="160" show-overflow-tooltip />
        <el-table-column prop="category" label="分类" width="100">
          <template #default="{ row }">{{ categoryLabels[row.category] || row.category }}</template>
        </el-table-column>
        <el-table-column prop="stepCount" label="步骤数" width="80" align="center" />
        <el-table-column prop="useCount" label="使用次数" width="100" align="center" />
        <el-table-column prop="updatedAt" label="更新时间" width="170" />
        <el-table-column label="操作" width="240" fixed="right">
          <template #default="{ row }">
            <el-button size="small" text type="primary" @click="handleUse(row)">使用</el-button>
            <el-button size="small" text type="primary" @click="handleEdit(row)">编辑</el-button>
            <el-button size="small" text type="danger" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination-wrapper">
        <el-pagination
          v-model:current-page="page"
          v-model:page-size="pageSize"
          :total="total"
          :page-sizes="[10, 20, 50]"
          layout="total, sizes, prev, pager, next"
          @size-change="fetchData"
          @current-change="fetchData"
        />
      </div>
    </div>

    <!-- 创建/编辑模板对话框 -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="800px" destroy-on-close top="5vh">
      <el-form ref="formRef" :model="formData" :rules="formRules" label-width="80px">
        <el-form-item label="模板名称" prop="name">
          <el-input v-model="formData.name" placeholder="请输入模板名称" />
        </el-form-item>
        <el-form-item label="分类" prop="category">
          <el-select v-model="formData.category" placeholder="请选择分类">
            <el-option v-for="(label, value) in categoryLabels" :key="value" :label="label" :value="value" />
          </el-select>
        </el-form-item>
        <el-form-item label="描述">
          <el-input v-model="formData.description" type="textarea" :rows="2" placeholder="模板描述" />
        </el-form-item>
        <el-form-item label="步骤">
          <StepEditor v-model="formData.steps" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="submitLoading" @click="handleSubmit">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
/**
 * TemplateList - 任务模板管理页面
 */
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Search } from '@element-plus/icons-vue'
import PageHeader from '@/components/PageHeader.vue'
import StepEditor from '@/components/StepEditor.vue'
import { getTemplateList, createTemplate, updateTemplate, deleteTemplate, createTaskFromTemplate } from '@/api/task'

const router = useRouter()
const loading = ref(false)
const submitLoading = ref(false)
const templateList = ref([])
const total = ref(0)
const page = ref(1)
const pageSize = ref(20)
const keyword = ref('')
const category = ref('')
const dialogVisible = ref(false)
const dialogTitle = ref('创建模板')
const editingId = ref(null)
const formRef = ref(null)

const categoryLabels = { cleaning: '清洁', organizing: '整理', transport: '搬运', packaging: '包装', other: '其他' }

const formData = reactive({ name: '', category: '', description: '', steps: [] })
const formRules = {
  name: [{ required: true, message: '请输入模板名称', trigger: 'blur' }],
  category: [{ required: true, message: '请选择分类', trigger: 'change' }]
}

async function fetchData() {
  loading.value = true
  try {
    const res = await getTemplateList({ page: page.value, pageSize: pageSize.value, keyword: keyword.value, category: category.value })
    templateList.value = res.data?.list || res.data?.data?.list || []
    total.value = res.data?.total || res.data?.pagination?.total || 0
  } catch (error) {
    console.error('获取模板列表失败:', error)
  } finally {
    loading.value = false
  }
}

function handleCreate() {
  editingId.value = null
  dialogTitle.value = '创建模板'
  Object.assign(formData, { name: '', category: '', description: '', steps: [] })
  dialogVisible.value = true
}

async function handleEdit(row) {
  editingId.value = row.id
  dialogTitle.value = '编辑模板'
  
  // 获取模板详情以加载步骤
  try {
    const { getTemplateDetail } = await import('@/api/task')
    const res = await getTemplateDetail(row.id)
    const template = res.data
    if (template) {
      Object.assign(formData, {
        name: template.name || template.title || row.name,
        category: template.category || row.category,
        description: template.description || row.description || '',
        steps: (template.steps || []).map((s, index) => ({
          id: s.id || `step-${Date.now()}-${index}`,
          title: s.title || '',
          description: s.description || '',
          imageUrl: s.imageUrl || '',
          audioUrl: s.audioUrl || '',
          isKey: s.isKey || false,
          sortOrder: s.sortOrder || index
        }))
      })
    }
  } catch (error) {
    console.error('获取模板详情失败:', error)
    // 回退到使用列表数据
    Object.assign(formData, { name: row.name, category: row.category, description: row.description || '', steps: row.steps || [] })
  }
  
  dialogVisible.value = true
}

async function handleUse(row) {
  try {
    await ElMessageBox.confirm(`使用模板 "${row.name}" 创建任务？`, '确认', { type: 'info' })
    router.push({ path: '/tasks/create', query: { templateId: row.id } })
  } catch (error) {
    if (error !== 'cancel') console.error(error)
  }
}

async function handleSubmit() {
  try { await formRef.value.validate() } catch { return }
  submitLoading.value = true
  try {
    if (editingId.value) {
      await updateTemplate(editingId.value, formData)
      ElMessage.success('更新成功')
    } else {
      await createTemplate(formData)
      ElMessage.success('创建成功')
    }
    dialogVisible.value = false
    fetchData()
  } catch (error) {
    console.error('保存失败:', error)
  } finally {
    submitLoading.value = false
  }
}

async function handleDelete(row) {
  try {
    await ElMessageBox.confirm(`确定删除模板 "${row.name}" 吗？`, '确认删除', { type: 'warning' })
    await deleteTemplate(row.id)
    ElMessage.success('删除成功')
    fetchData()
  } catch (error) {
    if (error !== 'cancel') console.error('删除失败:', error)
  }
}

onMounted(() => { fetchData() })
</script>

<style scoped>
.pagination-wrapper { display: flex; justify-content: flex-end; margin-top: 16px; }
</style>
