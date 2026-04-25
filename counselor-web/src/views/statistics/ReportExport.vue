<template>
  <!-- 报表导出页面 -->
  <div class="report-export-page page-container">
    <PageHeader title="报表导出" :show-back="true" />

    <div class="export-layout">
      <!-- 导出配置 -->
      <div class="card-container export-config">
        <h3 class="section-title">导出配置</h3>
        <el-form :model="exportForm" label-width="100px">
          <el-form-item label="报表类型">
            <el-select v-model="exportForm.type" placeholder="选择报表类型" style="width: 100%">
              <el-option label="任务完成报表" value="task_completion" />
              <el-option label="步骤耗时报表" value="step_duration" />
              <el-option label="情绪统计报表" value="emotion_stats" />
              <el-option label="员工工作报表" value="employee_work" />
              <el-option label="综合报表" value="comprehensive" />
            </el-select>
          </el-form-item>
          <el-form-item label="导出格式">
            <el-radio-group v-model="exportForm.format">
              <el-radio value="xlsx">Excel (.xlsx)</el-radio>
              <el-radio value="pdf">PDF</el-radio>
              <el-radio value="csv">CSV</el-radio>
            </el-radio-group>
          </el-form-item>
          <el-form-item label="日期范围">
            <el-date-picker
              v-model="exportForm.dateRange"
              type="daterange"
              range-separator="至"
              start-placeholder="开始日期"
              end-placeholder="结束日期"
              value-format="YYYY-MM-DD"
              style="width: 100%"
            />
          </el-form-item>
          <el-form-item label="选择员工">
            <el-select v-model="exportForm.employeeIds" multiple placeholder="不选则导出全部" style="width: 100%">
              <el-option v-for="emp in employeeOptions" :key="emp.id" :label="emp.name" :value="emp.id" />
            </el-select>
          </el-form-item>
          <el-form-item>
            <el-button type="primary" :icon="Download" :loading="exporting" @click="handleExport">
              导出报表
            </el-button>
          </el-form-item>
        </el-form>
      </div>

      <!-- 历史导出记录 -->
      <div class="card-container export-history">
        <h3 class="section-title">历史导出记录</h3>
        <el-table :data="historyList" stripe size="small">
          <el-table-column prop="reportName" label="报表名称" min-width="160" show-overflow-tooltip />
          <el-table-column prop="type" label="类型" width="120" />
          <el-table-column prop="format" label="格式" width="80" align="center" />
          <el-table-column prop="dateRange" label="日期范围" width="200" />
          <el-table-column prop="createdAt" label="导出时间" width="170" />
          <el-table-column label="操作" width="100">
            <template #default="{ row }">
              <el-button size="small" text type="primary" :icon="Download" @click="handleDownload(row)">
                下载
              </el-button>
            </template>
          </el-table-column>
        </el-table>
        <el-empty v-if="historyList.length === 0" description="暂无导出记录" :image-size="60" />
      </div>
    </div>
  </div>
</template>

<script setup>
/**
 * ReportExport - 报表导出页面
 */
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Download } from '@element-plus/icons-vue'
import PageHeader from '@/components/PageHeader.vue'
import { exportReport } from '@/api/statistics'
import { downloadFile } from '@/utils/helpers'
import { getEmployeeList } from '@/api/user'
import dayjs from 'dayjs'

const exporting = ref(false)
const employeeOptions = ref([])
const historyList = ref([
  { id: '1', reportName: '1月份任务完成报表', type: '任务完成', format: 'xlsx', dateRange: '2025-01-01 ~ 2025-01-31', createdAt: '2025-02-01 09:00' },
  { id: '2', reportName: '12月份情绪统计报表', type: '情绪统计', format: 'pdf', dateRange: '2024-12-01 ~ 2024-12-31', createdAt: '2025-01-02 10:30' }
])

const exportForm = reactive({
  type: 'task_completion',
  format: 'xlsx',
  dateRange: [dayjs().startOf('month').format('YYYY-MM-DD'), dayjs().format('YYYY-MM-DD')],
  employeeIds: []
})

async function handleExport() {
  if (!exportForm.dateRange) {
    ElMessage.warning('请选择日期范围')
    return
  }

  exporting.value = true
  try {
    const blob = await exportReport({
      type: exportForm.type,
      format: exportForm.format,
      startDate: exportForm.dateRange[0],
      endDate: exportForm.dateRange[1],
      employeeIds: exportForm.employeeIds
    })
    const filename = `报表_${exportForm.type}_${dayjs().format('YYYYMMDD')}.${exportForm.format}`
    downloadFile(blob, filename)
    ElMessage.success('报表导出成功')
  } catch (error) {
    console.error('导出失败:', error)
    ElMessage.error('导出失败，请重试')
  } finally {
    exporting.value = false
  }
}

function handleDownload(row) {
  ElMessage.info('开始下载: ' + row.reportName)
}

onMounted(() => {
  getEmployeeList({ page: 1, pageSize: 100 }).then(res => {
    employeeOptions.value = res.data?.list || []
  }).catch(() => {})
})
</script>

<style scoped>
.section-title {
  margin: 0 0 16px;
  font-size: 15px;
  font-weight: 600;
  color: #303133;
}

.export-layout {
  display: grid;
  grid-template-columns: 400px 1fr;
  gap: 16px;
  align-items: start;
}

@media screen and (max-width: 1024px) {
  .export-layout {
    grid-template-columns: 1fr;
  }
}
</style>
