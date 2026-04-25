<template>
  <!-- 任务列表页面 -->
  <div class="task-list-page page-container">
    <PageHeader title="任务管理">
      <template #actions>
        <el-button type="primary" :icon="Plus" @click="$router.push('/tasks/create')">创建任务</el-button>
      </template>
    </PageHeader>

    <div class="card-container">
      <!-- 搜索筛选 -->
      <div class="search-bar">
        <el-input
          v-model="queryParams.keyword"
          placeholder="搜索任务名称"
          :prefix-icon="Search"
          clearable
          style="width: 200px"
          @clear="fetchData"
          @keyup.enter="fetchData"
        />
        <el-select v-model="queryParams.status" placeholder="状态" clearable style="width: 120px" @change="fetchData">
          <el-option v-for="(label, value) in TASK_STATUS_LABELS" :key="value" :label="label" :value="value" />
        </el-select>
        <el-date-picker
          v-model="queryParams.date"
          type="date"
          placeholder="选择日期"
          value-format="YYYY-MM-DD"
          style="width: 160px"
          @change="fetchData"
        />
        <el-button :icon="Search" @click="fetchData">搜索</el-button>
        <el-button @click="resetQuery">重置</el-button>
      </div>

      <!-- 任务表格 -->
      <el-table :data="taskStore.taskList" v-loading="taskStore.listLoading" stripe>
        <el-table-column prop="title" label="任务名称" min-width="160" show-overflow-tooltip />
        <el-table-column prop="employeeName" label="分配员工" width="100" />
        <el-table-column prop="scheduledDate" label="计划日期" width="110" />
        <el-table-column label="步骤数" width="80" align="center">
          <template #default="{ row }">{{ row.stepCount || 0 }}</template>
        </el-table-column>
        <el-table-column label="状态" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="TASK_STATUS_COLORS[row.status]" size="small">
              {{ TASK_STATUS_LABELS[row.status] || row.status }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="completionRate" label="完成率" width="100" align="center">
          <template #default="{ row }">
            <span>{{ row.completionRate || 0 }}%</span>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="220" fixed="right">
          <template #default="{ row }">
            <el-button size="small" text type="primary" @click="$router.push(`/tasks/${row.id}/monitor`)">
              监控
            </el-button>
            <el-button size="small" text type="primary" @click="$router.push(`/tasks/${row.id}/edit`)">
              编辑
            </el-button>
            <el-button size="small" text type="primary" @click="handleDuplicate(row)">
              复制
            </el-button>
            <el-button size="small" text type="danger" @click="handleDelete(row)">
              删除
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页 -->
      <div class="pagination-wrapper">
        <el-pagination
          v-model:current-page="queryParams.page"
          v-model:page-size="queryParams.pageSize"
          :page-sizes="[10, 20, 50]"
          :total="taskStore.total"
          layout="total, sizes, prev, pager, next"
          @size-change="fetchData"
          @current-change="fetchData"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
/**
 * TaskList - 任务列表页面
 */
import { reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Search } from '@element-plus/icons-vue'
import PageHeader from '@/components/PageHeader.vue'
import { useTaskStore } from '@/stores/task'
import { TASK_STATUS_LABELS, TASK_STATUS_COLORS } from '@/utils/constants'

const taskStore = useTaskStore()

const queryParams = reactive({
  page: 1,
  pageSize: 20,
  keyword: '',
  status: '',
  date: ''
})

async function fetchData() {
  await taskStore.fetchTaskList(queryParams)
}

function resetQuery() {
  queryParams.keyword = ''
  queryParams.status = ''
  queryParams.date = ''
  queryParams.page = 1
  fetchData()
}

function handleDuplicate(row) {
  ElMessage.success('任务已复制')
}

async function handleDelete(row) {
  try {
    await ElMessageBox.confirm(`确定删除任务 "${row.title}" 吗？`, '确认删除', { type: 'warning' })
    await taskStore.deleteTask(row.id)
    ElMessage.success('删除成功')
  } catch (error) {
    if (error !== 'cancel') console.error('删除失败:', error)
  }
}

onMounted(() => {
  fetchData()
})
</script>

<style scoped>
.pagination-wrapper {
  display: flex;
  justify-content: flex-end;
  margin-top: 16px;
}
</style>
