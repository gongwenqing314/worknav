<template>
  <!-- 排班管理页面：日历视图 + 批量任务分配 -->
  <div class="schedule-page page-container">
    <PageHeader title="排班管理">
      <template #actions>
        <el-button type="primary" :icon="Plus" @click="showBatchDialog">批量排班</el-button>
      </template>
    </PageHeader>

    <div class="schedule-layout">
      <!-- 日历区域 -->
      <div class="card-container schedule-calendar">
        <!-- 月份切换 -->
        <div class="calendar-header">
          <el-button :icon="ArrowLeft" circle @click="prevMonth" />
          <span class="calendar-title">{{ currentMonth }}</span>
          <el-button :icon="ArrowRight" circle @click="nextMonth" />
          <el-button size="small" @click="goToday">今天</el-button>
        </div>

        <!-- 日历网格 -->
        <div class="calendar-grid">
          <!-- 星期头 -->
          <div class="calendar-weekdays">
            <div v-for="day in weekdays" :key="day" class="weekday-cell">{{ day }}</div>
          </div>
          <!-- 日期格子 -->
          <div class="calendar-days">
            <div
              v-for="(day, index) in calendarDays"
              :key="index"
              class="day-cell"
              :class="{
                'day-cell--other': !day.isCurrentMonth,
                'day-cell--today': day.isToday,
                'day-cell--selected': isSelected(day.date)
              }"
              @click="selectDate(day.date)"
            >
              <span class="day-number">{{ day.day }}</span>
              <div class="day-tasks">
                <el-tag
                  v-for="(task, i) in day.tasks?.slice(0, 2)"
                  :key="i"
                  size="small"
                  :type="task.type"
                  class="day-task-tag"
                >
                  {{ task.label }}
                </el-tag>
                <span v-if="day.tasks?.length > 2" class="day-more">+{{ day.tasks.length - 2 }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 右侧：选中日期的排班详情 -->
      <div class="schedule-detail">
        <div class="card-container">
          <h3 class="section-title">{{ selectedDateLabel }} 排班</h3>
          <el-table :data="daySchedules" v-loading="detailLoading" stripe size="small">
            <el-table-column prop="employeeName" label="员工" width="80" />
            <el-table-column prop="taskName" label="任务" min-width="120" />
            <el-table-column prop="timeRange" label="时间段" width="120" />
            <el-table-column label="操作" width="120">
              <template #default="{ row }">
                <el-button size="small" text type="danger" @click="handleDeleteSchedule(row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
          <el-empty v-if="daySchedules.length === 0" description="当日无排班" :image-size="60" />
        </div>

        <!-- 快速添加排班 -->
        <div class="card-container mt-md">
          <h3 class="section-title">快速添加</h3>
          <el-form :model="quickForm" label-width="60px" size="small">
            <el-form-item label="员工">
              <el-select v-model="quickForm.employeeId" placeholder="选择员工" style="width: 100%">
                <el-option v-for="emp in employeeOptions" :key="emp.id" :label="emp.name" :value="emp.id" />
              </el-select>
            </el-form-item>
            <el-form-item label="任务">
              <el-select v-model="quickForm.taskId" placeholder="选择任务" style="width: 100%">
                <el-option v-for="task in taskOptions" :key="task.id" :label="task.title" :value="task.id" />
              </el-select>
            </el-form-item>
            <el-form-item label="时间">
              <el-time-picker v-model="quickForm.timeRange" is-range range-separator="至" start-placeholder="开始" end-placeholder="结束" style="width: 100%" />
            </el-form-item>
            <el-form-item>
              <el-button type="primary" @click="handleQuickAdd">添加</el-button>
            </el-form-item>
          </el-form>
        </div>
      </div>
    </div>

    <!-- 批量排班对话框 -->
    <el-dialog v-model="batchDialogVisible" title="批量排班" width="600px">
      <el-form :model="batchForm" label-width="100px">
        <el-form-item label="选择员工">
          <el-select v-model="batchForm.employeeIds" multiple placeholder="选择员工" style="width: 100%">
            <el-option v-for="emp in employeeOptions" :key="emp.id" :label="emp.name" :value="emp.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="选择任务">
          <el-select v-model="batchForm.taskId" placeholder="选择任务" style="width: 100%">
            <el-option v-for="task in taskOptions" :key="task.id" :label="task.title" :value="task.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="日期范围">
          <el-date-picker v-model="batchForm.dateRange" type="daterange" range-separator="至" start-placeholder="开始日期" end-placeholder="结束日期" value-format="YYYY-MM-DD" style="width: 100%" />
        </el-form-item>
        <el-form-item label="时间段">
          <el-time-picker v-model="batchForm.timeRange" is-range range-separator="至" start-placeholder="开始" end-placeholder="结束" style="width: 100%" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="batchDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="batchLoading" @click="handleBatchCreate">确认排班</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
/**
 * ScheduleManage - 排班管理页面
 * 日历视图 + 批量任务分配
 */
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Plus, ArrowLeft, ArrowRight } from '@element-plus/icons-vue'
import PageHeader from '@/components/PageHeader.vue'
import dayjs from 'dayjs'
import { getScheduleCalendar, createSchedule, batchCreateSchedules, deleteSchedule } from '@/api/schedule'
import { getEmployeeList } from '@/api/user'
import { getTaskList } from '@/api/task'

const weekdays = ['一', '二', '三', '四', '五', '六', '日']
const currentDate = ref(dayjs())
const selectedDate = ref(dayjs().format('YYYY-MM-DD'))
const calendarDays = ref([])
const daySchedules = ref([])
const detailLoading = ref(false)
const employeeOptions = ref([])
const taskOptions = ref([])
const batchDialogVisible = ref(false)
const batchLoading = ref(false)

const currentMonth = computed(() => currentDate.value.format('YYYY年MM月'))
const selectedDateLabel = computed(() => selectedDate.value)

const quickForm = reactive({ employeeId: '', taskId: '', timeRange: null })
const batchForm = reactive({ employeeIds: [], taskId: '', dateRange: null, timeRange: null })

function isSelected(date) {
  return date === selectedDate.value
}

function prevMonth() {
  currentDate.value = currentDate.value.subtract(1, 'month')
  generateCalendar()
}

function nextMonth() {
  currentDate.value = currentDate.value.add(1, 'month')
  generateCalendar()
}

function goToday() {
  currentDate.value = dayjs()
  selectedDate.value = dayjs().format('YYYY-MM-DD')
  generateCalendar()
  fetchDaySchedules()
}

function selectDate(date) {
  if (!date) return
  selectedDate.value = date
  fetchDaySchedules()
}

function generateCalendar() {
  const start = currentDate.value.startOf('month').startOf('week').add(1, 'day')
  const end = currentDate.value.endOf('month').endOf('week').add(1, 'day')
  const days = []
  let cursor = start
  while (cursor.isBefore(end) || cursor.isSame(end, 'day')) {
    days.push({
      day: cursor.date(),
      date: cursor.format('YYYY-MM-DD'),
      isCurrentMonth: cursor.month() === currentDate.value.month(),
      isToday: cursor.isSame(dayjs(), 'day'),
      tasks: generateMockTasks(cursor)
    })
    cursor = cursor.add(1, 'day')
  }
  calendarDays.value = days
}

function generateMockTasks(date) {
  const day = date.day()
  if (day === 0 || day === 6) return []
  const tasks = []
  if (day % 3 === 0) tasks.push({ label: '清洁', type: 'success' })
  if (day % 2 === 0) tasks.push({ label: '整理', type: 'primary' })
  if (day % 5 === 0) tasks.push({ label: '搬运', type: 'warning' })
  return tasks
}

async function fetchDaySchedules() {
  detailLoading.value = true
  try {
    const res = await getScheduleCalendar({ date: selectedDate.value })
    daySchedules.value = Array.isArray(res.data) ? res.data : (res.data?.list || res.data?.schedules || [])
  } catch (error) {
    console.error('获取排班失败:', error)
    daySchedules.value = []
  } finally {
    detailLoading.value = false
  }
}

async function fetchOptions() {
  try {
    const [empRes, taskRes] = await Promise.allSettled([
      getEmployeeList({ page: 1, pageSize: 100, status: 'active' }),
      getTaskList({ page: 1, pageSize: 100, status: 'pending' })
    ])
    employeeOptions.value = empRes.status === 'fulfilled' ? (empRes.value.data?.list || []) : []
    taskOptions.value = taskRes.status === 'fulfilled' ? (taskRes.value.data?.list || []) : []
  } catch (error) {
    console.error('获取选项失败:', error)
    employeeOptions.value = []
    taskOptions.value = []
  }
}

function showBatchDialog() {
  batchForm.employeeIds = []
  batchForm.taskId = ''
  batchForm.dateRange = null
  batchForm.timeRange = null
  batchDialogVisible.value = true
}

async function handleQuickAdd() {
  if (!quickForm.employeeId || !quickForm.taskId) {
    ElMessage.warning('请选择员工和任务')
    return
  }
  try {
    await createSchedule({
      employeeId: quickForm.employeeId,
      taskId: quickForm.taskId,
      date: selectedDate.value,
      startTime: quickForm.timeRange?.[0] || '09:00',
      endTime: quickForm.timeRange?.[1] || '17:00'
    })
    ElMessage.success('排班添加成功')
    fetchDaySchedules()
  } catch (error) {
    console.error('添加排班失败:', error)
  }
}

async function handleBatchCreate() {
  if (!batchForm.employeeIds.length || !batchForm.taskId || !batchForm.dateRange) {
    ElMessage.warning('请填写完整信息')
    return
  }
  batchLoading.value = true
  try {
    const items = []
    const start = dayjs(batchForm.dateRange[0])
    const end = dayjs(batchForm.dateRange[1])
    let cursor = start
    while (cursor.isBefore(end) || cursor.isSame(end, 'day')) {
      if (cursor.day() !== 0 && cursor.day() !== 6) {
        batchForm.employeeIds.forEach(empId => {
          items.push({
            employeeId: empId,
            taskId: batchForm.taskId,
            date: cursor.format('YYYY-MM-DD'),
            startTime: batchForm.timeRange?.[0] || '09:00',
            endTime: batchForm.timeRange?.[1] || '17:00'
          })
        })
      }
      cursor = cursor.add(1, 'day')
    }
    await batchCreateSchedules({ items })
    ElMessage.success('批量排班成功')
    batchDialogVisible.value = false
    generateCalendar()
    fetchDaySchedules()
  } catch (error) {
    console.error('批量排班失败:', error)
  } finally {
    batchLoading.value = false
  }
}

async function handleDeleteSchedule(row) {
  try {
    await deleteSchedule(row.id)
    ElMessage.success('排班已删除')
    fetchDaySchedules()
  } catch (error) {
    console.error('删除排班失败:', error)
  }
}

onMounted(() => {
  generateCalendar()
  fetchDaySchedules()
  fetchOptions()
})
</script>

<style scoped>
.schedule-layout {
  display: grid;
  grid-template-columns: 1fr 360px;
  gap: 16px;
  align-items: start;
}

.calendar-header {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 16px;
}

.calendar-title {
  font-size: 18px;
  font-weight: 600;
  color: #303133;
  min-width: 120px;
  text-align: center;
}

.calendar-weekdays {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 1px;
  background: #EBEEF5;
}

.weekday-cell {
  text-align: center;
  padding: 8px;
  font-size: 13px;
  font-weight: 500;
  color: #606266;
  background: #f5f7fa;
}

.calendar-days {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 1px;
  background: #EBEEF5;
}

.day-cell {
  min-height: 80px;
  padding: 6px;
  background: #fff;
  cursor: pointer;
  transition: background 0.2s;
}

.day-cell:hover {
  background: #f0f9ff;
}

.day-cell--other {
  background: #fafafa;
}

.day-cell--other .day-number {
  color: #C0C4CC;
}

.day-cell--today {
  background: #ecf5ff;
}

.day-cell--today .day-number {
  background: #409EFF;
  color: #fff;
  border-radius: 50%;
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.day-cell--selected {
  outline: 2px solid #409EFF;
  outline-offset: -2px;
}

.day-number {
  font-size: 13px;
  color: #303133;
  margin-bottom: 4px;
}

.day-tasks {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.day-task-tag {
  font-size: 11px;
  transform: scale(0.9);
  transform-origin: left;
}

.day-more {
  font-size: 11px;
  color: #909399;
}

.section-title {
  margin: 0 0 12px;
  font-size: 15px;
  font-weight: 600;
  color: #303133;
}

@media screen and (max-width: 1024px) {
  .schedule-layout {
    grid-template-columns: 1fr;
  }
}
</style>
