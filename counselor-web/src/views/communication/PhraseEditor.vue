<template>
  <!-- 常用语编辑页面（独立路由入口） -->
  <div class="phrase-editor-page page-container">
    <PageHeader :title="`常用语编辑 - ${categoryName}`" :show-back="true">
      <template #actions>
        <el-button type="primary" :icon="Plus" @click="handleAdd">添加常用语</el-button>
      </template>
    </PageHeader>

    <div class="card-container">
      <el-table :data="phrases" v-loading="loading" stripe>
        <el-table-column type="index" label="序号" width="60" align="center" />
        <el-table-column prop="text" label="文字内容" min-width="200" show-overflow-tooltip />
        <el-table-column label="语音" width="100" align="center">
          <template #default="{ row }">
            <el-tag v-if="row.audioUrl" type="success" size="small">已录制</el-tag>
            <span v-else style="color: #C0C4CC; font-size: 12px;">未录制</span>
          </template>
        </el-table-column>
        <el-table-column label="配图" width="100" align="center">
          <template #default="{ row }">
            <el-image v-if="row.imageUrl" :src="row.imageUrl" style="width: 40px; height: 40px; border-radius: 4px;" fit="cover" :preview-src-list="[row.imageUrl]" />
            <span v-else style="color: #C0C4CC; font-size: 12px;">无</span>
          </template>
        </el-table-column>
        <el-table-column prop="sortOrder" label="排序" width="80" align="center" />
        <el-table-column label="操作" width="160" fixed="right">
          <template #default="{ row }">
            <el-button size="small" text type="primary" @click="handleEdit(row)">编辑</el-button>
            <el-button size="small" text type="danger" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 编辑对话框 -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="500px" destroy-on-close>
      <el-form :model="formData" label-width="80px">
        <el-form-item label="文字内容">
          <el-input v-model="formData.text" type="textarea" :rows="3" placeholder="请输入常用语文字" />
        </el-form-item>
        <el-form-item label="语音">
          <AudioRecorder v-model="formData.audioUrl" :max-duration="30" />
        </el-form-item>
        <el-form-item label="配图">
          <ImageUpload v-model="formData.imageUrl" />
        </el-form-item>
        <el-form-item label="排序号">
          <el-input-number v-model="formData.sortOrder" :min="0" :max="999" />
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
 * PhraseEditor - 常用语编辑页面
 * 独立路由入口，编辑指定分类下的常用语
 */
import { ref, reactive, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import PageHeader from '@/components/PageHeader.vue'
import ImageUpload from '@/components/ImageUpload.vue'
import AudioRecorder from '@/components/AudioRecorder.vue'
import { getPhrases, createPhrase, updatePhrase, deletePhrase } from '@/api/communication'

const route = useRoute()
const categoryId = route.params.categoryId
const categoryName = ref('')
const loading = ref(false)
const phrases = ref([])
const dialogVisible = ref(false)
const dialogTitle = ref('添加常用语')
const editingId = ref(null)
const formData = reactive({ text: '', audioUrl: '', imageUrl: '', sortOrder: 0 })

async function fetchData() {
  loading.value = true
  try {
    const res = await getPhrases(categoryId)
    phrases.value = res.data || []
    categoryName.value = phrases.value.length > 0 ? '分类' : '分类'
  } catch (error) {
    phrases.value = [
      { id: '1', text: '你好', audioUrl: '', imageUrl: '', sortOrder: 1 },
      { id: '2', text: '谢谢', audioUrl: '/audio/thanks.mp3', imageUrl: '', sortOrder: 2 }
    ]
    categoryName.value = '常用语'
  } finally {
    loading.value = false
  }
}

function handleAdd() {
  editingId.value = null
  dialogTitle.value = '添加常用语'
  Object.assign(formData, { text: '', audioUrl: '', imageUrl: '', sortOrder: phrases.value.length })
  dialogVisible.value = true
}

function handleEdit(row) {
  editingId.value = row.id
  dialogTitle.value = '编辑常用语'
  Object.assign(formData, row)
  dialogVisible.value = true
}

async function handleSave() {
  if (!formData.text) { ElMessage.warning('请输入文字内容'); return }
  try {
    if (editingId.value) {
      await updatePhrase(categoryId, editingId.value, formData)
      ElMessage.success('更新成功')
    } else {
      await createPhrase(categoryId, formData)
      ElMessage.success('添加成功')
    }
    dialogVisible.value = false
    fetchData()
  } catch (error) { console.error('保存失败:', error) }
}

async function handleDelete(row) {
  try {
    await ElMessageBox.confirm('确定删除该常用语吗？', '确认', { type: 'warning' })
    await deletePhrase(categoryId, row.id)
    ElMessage.success('删除成功')
    fetchData()
  } catch (error) { if (error !== 'cancel') console.error(error) }
}

onMounted(() => { fetchData() })
</script>
