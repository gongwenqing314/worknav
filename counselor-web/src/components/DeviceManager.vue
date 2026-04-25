<template>
  <!-- 设备管理组件：展示设备列表、在线状态、操作按钮 -->
  <div class="device-manager">
    <!-- 搜索栏 -->
    <div class="device-manager__toolbar">
      <el-input
        v-model="searchKeyword"
        placeholder="搜索设备/员工"
        :prefix-icon="Search"
        clearable
        style="width: 240px"
        @clear="handleSearch"
        @keyup.enter="handleSearch"
      />
      <el-select v-model="statusFilter" placeholder="设备状态" clearable style="width: 120px" @change="handleSearch">
        <el-option label="在线" value="online" />
        <el-option label="离线" value="offline" />
        <el-option label="已锁定" value="locked" />
      </el-select>
      <el-button type="primary" :icon="Refresh" @click="fetchDevices">刷新</el-button>
    </div>

    <!-- 设备列表 -->
    <el-table
      :data="filteredDevices"
      v-loading="loading"
      stripe
      style="width: 100%"
    >
      <el-table-column prop="deviceName" label="设备名称" min-width="140" show-overflow-tooltip />
      <el-table-column prop="employeeName" label="绑定员工" min-width="100" />
      <el-table-column label="在线状态" width="100" align="center">
        <template #default="{ row }">
          <div class="status-cell">
            <span class="status-dot" :class="`status-dot--${row.status}`"></span>
            <span>{{ statusLabels[row.status] || row.status }}</span>
          </div>
        </template>
      </el-table-column>
      <el-table-column prop="lastOnline" label="最后在线" width="160" />
      <el-table-column prop="bindTime" label="绑定时间" width="160" />
      <el-table-column label="操作" width="200" fixed="right">
        <template #default="{ row }">
          <el-button size="small" text type="primary" @click="handlePushConfig(row)">
            推送配置
          </el-button>
          <el-button
            v-if="row.status === 'online'"
            size="small"
            text
            type="warning"
            @click="handleLock(row)"
          >
            锁定
          </el-button>
          <el-button
            v-if="row.status === 'locked'"
            size="small"
            text
            type="success"
            @click="handleUnlock(row)"
          >
            解锁
          </el-button>
          <el-button size="small" text type="danger" @click="handleUnbind(row)">
            解绑
          </el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- 分页 -->
    <div class="device-manager__pagination">
      <el-pagination
        v-model:current-page="currentPage"
        v-model:page-size="pageSize"
        :page-sizes="[10, 20, 50]"
        :total="total"
        layout="total, sizes, prev, pager, next"
        @size-change="fetchDevices"
        @current-change="fetchDevices"
      />
    </div>

    <!-- 推送配置对话框 -->
    <el-dialog v-model="configDialogVisible" title="推送设备配置" width="500px">
      <el-form :model="configForm" label-width="100px">
        <el-form-item label="音量">
          <el-slider v-model="configForm.volume" :min="0" :max="100" />
        </el-form-item>
        <el-form-item label="字体大小">
          <el-select v-model="configForm.fontSize">
            <el-option label="小" value="small" />
            <el-option label="中" value="medium" />
            <el-option label="大" value="large" />
          </el-select>
        </el-form-item>
        <el-form-item label="提示音效">
          <el-switch v-model="configForm.soundEnabled" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="configDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="submitConfig">推送</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
/**
 * DeviceManager - 设备管理组件
 * 展示设备列表、在线状态，支持锁定/解锁/解绑/推送配置
 */
import { ref, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search, Refresh } from '@element-plus/icons-vue'
import { DEVICE_STATUS_LABELS } from '@/utils/constants'
import { getDeviceList, unbindDevice, lockDevice, unlockDevice, pushDeviceConfig } from '@/api/device'

// 搜索和筛选
const searchKeyword = ref('')
const statusFilter = ref('')
const loading = ref(false)

// 分页
const currentPage = ref(1)
const pageSize = ref(20)
const total = ref(0)

// 设备列表
const devices = ref([])

// 状态标签
const statusLabels = DEVICE_STATUS_LABELS

// 推送配置对话框
const configDialogVisible = ref(false)
const currentDevice = ref(null)
const configForm = ref({
  volume: 80,
  fontSize: 'medium',
  soundEnabled: true
})

// 过滤后的设备列表
const filteredDevices = computed(() => {
  return devices.value
})

/**
 * 获取设备列表
 */
async function fetchDevices() {
  loading.value = true
  try {
    const res = await getDeviceList({
      page: currentPage.value,
      pageSize: pageSize.value,
      keyword: searchKeyword.value,
      status: statusFilter.value
    })
    devices.value = res.data?.list || res.data || []
    total.value = res.data?.total || 0
  } catch (error) {
    console.error('获取设备列表失败:', error)
  } finally {
    loading.value = false
  }
}

/**
 * 搜索
 */
function handleSearch() {
  currentPage.value = 1
  fetchDevices()
}

/**
 * 推送配置
 */
function handlePushConfig(device) {
  currentDevice.value = device
  configDialogVisible.value = true
}

/**
 * 提交配置推送
 */
async function submitConfig() {
  if (!currentDevice.value) return
  try {
    await pushDeviceConfig(currentDevice.value.id, configForm.value)
    ElMessage.success('配置推送成功')
    configDialogVisible.value = false
  } catch (error) {
    console.error('推送配置失败:', error)
  }
}

/**
 * 锁定设备
 */
async function handleLock(device) {
  try {
    await ElMessageBox.confirm(`确定锁定设备 "${device.deviceName}" 吗？`, '确认锁定', {
      type: 'warning'
    })
    await lockDevice(device.id)
    ElMessage.success('设备已锁定')
    fetchDevices()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('锁定设备失败:', error)
    }
  }
}

/**
 * 解锁设备
 */
async function handleUnlock(device) {
  try {
    await unlockDevice(device.id)
    ElMessage.success('设备已解锁')
    fetchDevices()
  } catch (error) {
    console.error('解锁设备失败:', error)
  }
}

/**
 * 解绑设备
 */
async function handleUnbind(device) {
  try {
    await ElMessageBox.confirm(
      `确定解绑设备 "${device.deviceName}" 吗？解绑后员工将无法使用该设备。`,
      '确认解绑',
      { type: 'warning' }
    )
    await unbindDevice(device.id)
    ElMessage.success('设备已解绑')
    fetchDevices()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('解绑设备失败:', error)
    }
  }
}

onMounted(() => {
  fetchDevices()
})
</script>

<style scoped>
.device-manager__toolbar {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 16px;
  flex-wrap: wrap;
}

.status-cell {
  display: flex;
  align-items: center;
  gap: 6px;
  justify-content: center;
}

.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
}

.status-dot--online {
  background: #67C23A;
  box-shadow: 0 0 4px rgba(103, 194, 58, 0.5);
}

.status-dot--offline {
  background: #C0C4CC;
}

.status-dot--locked {
  background: #F56C6C;
}

.device-manager__pagination {
  display: flex;
  justify-content: flex-end;
  margin-top: 16px;
}

@media screen and (max-width: 768px) {
  .device-manager__toolbar {
    flex-direction: column;
    align-items: stretch;
  }
}
</style>
