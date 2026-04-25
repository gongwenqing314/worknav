<template>
  <!-- 员工详情页面 -->
  <div class="employee-detail-page page-container">
    <PageHeader :title="`${employee.name || '员工'}详情`" :show-back="true">
      <template #actions>
        <el-button type="primary" :icon="Edit" @click="handleEdit">编辑</el-button>
      </template>
    </PageHeader>

    <div class="detail-grid">
      <!-- 基本信息 -->
      <div class="card-container detail-card">
        <h3 class="card-title">基本信息</h3>
        <el-descriptions :column="2" border>
          <el-descriptions-item label="姓名">{{ employee.name }}</el-descriptions-item>
          <el-descriptions-item label="性别">{{ employee.gender === 'male' ? '男' : '女' }}</el-descriptions-item>
          <el-descriptions-item label="出生日期">{{ employee.birthDate }}</el-descriptions-item>
          <el-descriptions-item label="年龄">{{ employee.age }}岁</el-descriptions-item>
          <el-descriptions-item label="残疾类型">{{ employee.disabilityType }}</el-descriptions-item>
          <el-descriptions-item label="所属分组">{{ employee.groupName || '未分组' }}</el-descriptions-item>
          <el-descriptions-item label="监护人">{{ employee.guardianName }}</el-descriptions-item>
          <el-descriptions-item label="监护人电话">{{ employee.guardianPhone }}</el-descriptions-item>
          <el-descriptions-item label="状态">
            <el-tag :type="employee.status === 'active' ? 'success' : 'info'" size="small">
              {{ employee.status === 'active' ? '在职' : '离职' }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="备注" :span="2">{{ employee.remark || '无' }}</el-descriptions-item>
        </el-descriptions>
      </div>

      <!-- 绑定家长 -->
      <div class="card-container detail-card">
        <div class="card-header-row">
          <h3 class="card-title">绑定家长</h3>
          <el-button text type="primary" @click="$router.push(`/employees/${employeeId}/parent-bind`)">
            管理绑定
          </el-button>
        </div>
        <div v-if="parents.length > 0">
          <div v-for="parent in parents" :key="parent.id" class="parent-item">
            <el-avatar :size="36" icon="UserFilled" />
            <div class="parent-info">
              <div class="parent-name">{{ parent.name }}</div>
              <div class="parent-relation">{{ parent.relation }}</div>
            </div>
            <el-tag :type="parent.status === 'active' ? 'success' : 'info'" size="small">
              {{ parent.status === 'active' ? '已绑定' : '已解绑' }}
            </el-tag>
          </div>
        </div>
        <el-empty v-else description="暂无绑定家长" :image-size="60" />
      </div>

      <!-- 最近任务 -->
      <div class="card-container detail-card">
        <div class="card-header-row">
          <h3 class="card-title">最近任务</h3>
          <el-button text type="primary" @click="$router.push('/tasks')">查看全部</el-button>
        </div>
        <el-table :data="recentTasks" stripe size="small">
          <el-table-column prop="taskName" label="任务名称" show-overflow-tooltip />
          <el-table-column prop="date" label="日期" width="110" />
          <el-table-column label="进度" width="100">
            <template #default="{ row }">
              <el-progress :percentage="row.progress" :stroke-width="6" :text-inside="true" />
            </template>
          </el-table-column>
          <el-table-column label="状态" width="80" align="center">
            <template #default="{ row }">
              <el-tag :type="row.statusType" size="small">{{ row.statusLabel }}</el-tag>
            </template>
          </el-table-column>
        </el-table>
      </div>

      <!-- 情绪趋势 -->
      <div class="card-container detail-card">
        <h3 class="card-title">情绪趋势</h3>
        <EmotionChart :employee-id="employeeId" height="250px" />
      </div>
    </div>
  </div>
</template>

<script setup>
/**
 * EmployeeDetail - 员工详情页面
 * 展示员工基本信息、绑定家长、最近任务、情绪趋势
 */
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Edit } from '@element-plus/icons-vue'
import PageHeader from '@/components/PageHeader.vue'
import EmotionChart from '@/components/EmotionChart.vue'
import { getEmployeeDetail, getParentBindings } from '@/api/user'

const route = useRoute()
const router = useRouter()
const employeeId = route.params.id

const employee = ref({})
const parents = ref([])
const recentTasks = ref([
  { taskName: '办公室清洁', date: '2025-01-15', progress: 100, statusLabel: '已完成', statusType: 'success' },
  { taskName: '文件整理', date: '2025-01-14', progress: 80, statusLabel: '执行中', statusType: 'primary' },
  { taskName: '物料搬运', date: '2025-01-13', progress: 100, statusLabel: '已完成', statusType: 'success' }
])

async function fetchEmployee() {
  try {
    const res = await getEmployeeDetail(employeeId)
    employee.value = res.data || {}
  } catch (error) {
    console.error('获取员工详情失败:', error)
  }
}

async function fetchParents() {
  try {
    const res = await getParentBindings(employeeId)
    parents.value = res.data || []
  } catch (error) {
    console.error('获取家长绑定失败:', error)
  }
}

function handleEdit() {
  router.push('/employees')
}

onMounted(() => {
  fetchEmployee()
  fetchParents()
})
</script>

<style scoped>
.detail-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
}

.detail-card {
  min-height: 200px;
}

.card-title {
  margin: 0 0 16px;
  font-size: 16px;
  color: #303133;
}

.card-header-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16px;
}

.card-header-row .card-title {
  margin-bottom: 0;
}

/* 家长列表 */
.parent-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 0;
  border-bottom: 1px solid #f0f0f0;
}

.parent-item:last-child {
  border-bottom: none;
}

.parent-info {
  flex: 1;
}

.parent-name {
  font-size: 14px;
  font-weight: 500;
  color: #303133;
}

.parent-relation {
  font-size: 12px;
  color: #909399;
}

@media screen and (max-width: 1024px) {
  .detail-grid {
    grid-template-columns: 1fr;
  }
}
</style>
