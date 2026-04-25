<template>
  <!-- 员工列表页面 -->
  <div class="employee-list-page page-container">
    <PageHeader title="员工管理">
      <template #actions>
        <el-button type="primary" :icon="Plus" @click="handleCreate">新增员工</el-button>
      </template>
    </PageHeader>

    <div class="card-container">
      <!-- 搜索栏 -->
      <div class="search-bar">
        <el-input
          v-model="queryParams.keyword"
          placeholder="搜索员工姓名/手机号"
          :prefix-icon="Search"
          clearable
          style="width: 240px"
          @clear="fetchData"
          @keyup.enter="fetchData"
        />
        <el-select v-model="queryParams.status" placeholder="状态" clearable style="width: 120px" @change="fetchData">
          <el-option label="在职" value="active" />
          <el-option label="离职" value="inactive" />
        </el-select>
        <el-select v-model="queryParams.groupId" placeholder="分组" clearable style="width: 140px" @change="fetchData">
          <el-option v-for="g in groups" :key="g.id" :label="g.name" :value="g.id" />
        </el-select>
        <el-button :icon="Search" @click="fetchData">搜索</el-button>
        <el-button @click="resetQuery">重置</el-button>
      </div>

      <!-- 数据表格 -->
      <el-table :data="employeeList" v-loading="loading" stripe>
        <el-table-column prop="name" label="姓名" width="100" />
        <el-table-column prop="gender" label="性别" width="70" align="center">
          <template #default="{ row }">{{ row.gender === 'male' ? '男' : '女' }}</template>
        </el-table-column>
        <el-table-column prop="age" label="年龄" width="70" align="center" />
        <el-table-column prop="disabilityType" label="残疾类型" width="120">
          <template #default="{ row }">
            {{ disabilityTypeMap[row.disabilityType] || row.disabilityType || '-' }}
          </template>
        </el-table-column>
        <el-table-column prop="groupName" label="所属分组" width="120" />
        <el-table-column prop="guardianName" label="监护人" width="100" />
        <el-table-column prop="guardianPhone" label="监护人电话" width="130" />
        <el-table-column label="状态" width="80" align="center">
          <template #default="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : 'info'" size="small">
              {{ row.status === 1 ? '在职' : '离职' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="240" fixed="right">
          <template #default="{ row }">
            <el-button size="small" text type="primary" @click="handleView(row)">查看</el-button>
            <el-button size="small" text type="primary" @click="handleEdit(row)">编辑</el-button>
            <el-button size="small" text type="primary" @click="$router.push(`/employees/${row.id}/parent-bind`)">
              家长绑定
            </el-button>
            <el-button size="small" text type="danger" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页 -->
      <div class="pagination-wrapper">
        <el-pagination
          v-model:current-page="queryParams.page"
          v-model:page-size="queryParams.pageSize"
          :page-sizes="[10, 20, 50]"
          :total="total"
          layout="total, sizes, prev, pager, next"
          @size-change="fetchData"
          @current-change="fetchData"
        />
      </div>
    </div>

    <!-- 新增/编辑对话框 -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="600px" destroy-on-close>
      <el-form ref="formRef" :model="formData" :rules="formRules" label-width="100px">
        <el-form-item label="姓名" prop="name">
          <el-input v-model="formData.name" placeholder="请输入姓名" />
        </el-form-item>
        <el-form-item label="性别" prop="gender">
          <el-radio-group v-model="formData.gender">
            <el-radio value="male">男</el-radio>
            <el-radio value="female">女</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="出生日期" prop="birthDate">
          <el-date-picker v-model="formData.birthDate" type="date" placeholder="选择日期" value-format="YYYY-MM-DD" />
        </el-form-item>
        <el-form-item label="残疾类型" prop="disabilityType">
          <el-select v-model="formData.disabilityType" placeholder="请选择">
            <el-option label="智力障碍" value="intellectual" />
            <el-option label="自闭症" value="autism" />
            <el-option label="唐氏综合征" value="down_syndrome" />
            <el-option label="其他" value="other" />
          </el-select>
        </el-form-item>
        <el-form-item label="所属分组" prop="groupId">
          <el-select v-model="formData.groupId" placeholder="请选择分组" clearable>
            <el-option v-for="g in groups" :key="g.id" :label="g.name" :value="g.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="监护人" prop="guardianName">
          <el-input v-model="formData.guardianName" placeholder="监护人姓名" />
        </el-form-item>
        <el-form-item label="监护人电话" prop="guardianPhone">
          <el-input v-model="formData.guardianPhone" placeholder="监护人手机号" maxlength="11" />
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="formData.remark" type="textarea" :rows="3" placeholder="备注信息" />
        </el-form-item>
        <el-form-item label="状态" prop="status">
          <el-radio-group v-model="formData.status">
            <el-radio :value="1">在职</el-radio>
            <el-radio :value="0">离职</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="submitLoading" @click="handleSubmit">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
/**
 * EmployeeList - 员工列表页面
 * 支持搜索、筛选、新增、编辑、删除
 */
import { ref, reactive, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Search } from '@element-plus/icons-vue'
import PageHeader from '@/components/PageHeader.vue'
import { getEmployeeList, createEmployee, updateEmployee, deleteEmployee, getGroups } from '@/api/user'
import { requiredRule, phoneRule } from '@/utils/validators'

const disabilityTypeMap = {
  intellectual: '智力障碍',
  autism: '自闭症',
  down_syndrome: '唐氏综合征',
  other: '其他'
}

const route = useRoute()
const router = useRouter()
const loading = ref(false)
const submitLoading = ref(false)
const employeeList = ref([])
const total = ref(0)
const groups = ref([])
const dialogVisible = ref(false)
const dialogTitle = ref('新增员工')
const editingId = ref(null)
const formRef = ref(null)

const queryParams = reactive({
  page: 1,
  pageSize: 20,
  keyword: '',
  status: '',
  groupId: ''
})

const formData = reactive({
  name: '',
  gender: 'male',
  birthDate: '',
  disabilityType: '',
  groupId: '',
  guardianName: '',
  guardianPhone: '',
  remark: '',
  status: 1
})

const formRules = {
  name: [requiredRule('姓名')],
  gender: [requiredSelectRule('性别')],
  birthDate: [requiredSelectRule('出生日期')],
  disabilityType: [requiredSelectRule('残疾类型')],
  guardianPhone: [phoneRule]
}

function requiredSelectRule(label) {
  return { required: true, message: `请选择${label}`, trigger: 'change' }
}

async function fetchData() {
  loading.value = true
  try {
    const res = await getEmployeeList(queryParams)
    employeeList.value = res.data?.list || res.data?.data?.list || []
    total.value = res.data?.total || res.data?.pagination?.total || 0
  } catch (error) {
    console.error('获取员工列表失败:', error)
  } finally {
    loading.value = false
  }
}

async function fetchGroups() {
  try {
    const res = await getGroups()
    groups.value = res.data || []
  } catch (error) {
    console.error('获取分组失败:', error)
  }
}

function resetQuery() {
  queryParams.keyword = ''
  queryParams.status = ''
    queryParams.groupId = ''
    queryParams.page = 1
    fetchData()
}

function handleCreate() {
  editingId.value = null
  dialogTitle.value = '新增员工'
  Object.assign(formData, { name: '', gender: 'male', birthDate: '', disabilityType: '', groupId: '', guardianName: '', guardianPhone: '', remark: '', status: 1 })
  dialogVisible.value = true
}

function handleEdit(row) {
  editingId.value = row.id
  dialogTitle.value = '编辑员工'
  formData.name = row.name || ''
  formData.gender = row.gender || 'male'
  formData.birthDate = row.birthDate || ''
  formData.disabilityType = row.disabilityType || ''
  formData.groupId = row.groupId || ''
  formData.guardianName = row.guardianName || ''
  formData.guardianPhone = row.guardianPhone || ''
  formData.remark = row.remark || ''
  formData.status = row.status !== undefined ? row.status : 1
  dialogVisible.value = true
}

function handleView(row) {
  router.push(`/employees/${row.id}`)
}

async function handleSubmit() {
  try {
    await formRef.value.validate()
  } catch { return }

  submitLoading.value = true
  try {
    if (editingId.value) {
      await updateEmployee(editingId.value, formData)
      ElMessage.success('更新成功')
    } else {
      await createEmployee(formData)
      ElMessage.success('创建成功')
    }
    dialogVisible.value = false
    await fetchData()
  } catch (error) {
    console.error('保存失败:', error)
  } finally {
    submitLoading.value = false
  }
}

async function handleDelete(row) {
  try {
    await ElMessageBox.confirm(`确定删除员工 "${row.name}" 吗？`, '确认删除', { type: 'warning' })
    await deleteEmployee(row.id)
    ElMessage.success('删除成功')
    fetchData()
  } catch (error) {
    if (error !== 'cancel') console.error('删除失败:', error)
  }
}

onMounted(() => {
  fetchData()
  fetchGroups()
})
</script>

<style scoped>
.pagination-wrapper {
  display: flex;
  justify-content: flex-end;
  margin-top: 16px;
}
</style>
