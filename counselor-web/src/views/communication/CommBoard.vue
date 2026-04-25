<template>
  <!-- 沟通板配置页面：分类管理 + 常用语编辑 -->
  <div class="comm-board-page page-container">
    <PageHeader title="沟通板配置">
      <template #actions>
        <el-button type="primary" :icon="Plus" @click="handleAddCategory">新增分类</el-button>
      </template>
    </PageHeader>

    <div class="comm-layout">
      <!-- 左侧：分类列表 -->
      <div class="card-container category-panel">
        <h3 class="section-title">分类管理</h3>
        <div class="category-list">
          <div
            v-for="cat in categories"
            :key="cat.id"
            class="category-item"
            :class="{ 'category-item--active': selectedCategory?.id === cat.id }"
            @click="selectCategory(cat)"
          >
            <el-icon :size="20" color="#409EFF"><Folder /></el-icon>
            <span class="category-name">{{ cat.name }}</span>
            <span class="category-count">{{ cat.phraseCount || 0 }}</span>
            <div class="category-actions" @click.stop>
              <el-button size="small" text :icon="Edit" @click="handleEditCategory(cat)" />
              <el-button size="small" text type="danger" :icon="Delete" @click="handleDeleteCategory(cat)" />
            </div>
          </div>
          <el-empty v-if="categories.length === 0" description="暂无分类" :image-size="60" />
        </div>
      </div>

      <!-- 右侧：常用语列表 -->
      <div class="phrases-panel">
        <div class="card-container" v-if="selectedCategory">
          <div class="phrases-header">
            <h3 class="section-title">{{ selectedCategory.name }} - 常用语</h3>
            <div class="phrases-actions">
              <el-button size="small" :icon="View" @click="handlePreview">预览</el-button>
              <el-button type="primary" size="small" :icon="Plus" @click="handleAddPhrase">添加常用语</el-button>
            </div>
          </div>

          <el-table :data="phrases" v-loading="phrasesLoading" stripe size="small">
            <el-table-column prop="text" label="文字内容" min-width="160" show-overflow-tooltip />
            <el-table-column label="语音" width="80" align="center">
              <template #default="{ row }">
                <el-tag v-if="row.audioUrl" type="success" size="small">已录</el-tag>
                <span v-else class="text-placeholder">未录</span>
              </template>
            </el-table-column>
            <el-table-column label="图片" width="80" align="center">
              <template #default="{ row }">
                <el-image v-if="row.imageUrl" :src="row.imageUrl" style="width: 32px; height: 32px; border-radius: 4px;" fit="cover" />
                <span v-else class="text-placeholder">无</span>
              </template>
            </el-table-column>
            <el-table-column prop="sortOrder" label="排序" width="70" align="center" />
            <el-table-column label="操作" width="140">
              <template #default="{ row }">
                <el-button size="small" text type="primary" @click="handleEditPhrase(row)">编辑</el-button>
                <el-button size="small" text type="danger" @click="handleDeletePhrase(row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </div>

        <div class="card-container empty-panel" v-else>
          <el-empty description="请选择左侧分类查看常用语" />
        </div>
      </div>
    </div>

    <!-- 分类编辑对话框 -->
    <el-dialog v-model="catDialogVisible" :title="catDialogTitle" width="400px">
      <el-form :model="catForm" label-width="60px">
        <el-form-item label="名称">
          <el-input v-model="catForm.name" placeholder="分类名称" />
        </el-form-item>
        <el-form-item label="图标">
          <el-input v-model="catForm.icon" placeholder="图标名称（如：food）" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="catDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSaveCategory">保存</el-button>
      </template>
    </el-dialog>

    <!-- 常用语编辑对话框 -->
    <el-dialog v-model="phraseDialogVisible" :title="phraseDialogTitle" width="500px" destroy-on-close>
      <el-form :model="phraseForm" label-width="80px">
        <el-form-item label="文字内容">
          <el-input v-model="phraseForm.text" type="textarea" :rows="2" placeholder="常用语文字" />
        </el-form-item>
        <el-form-item label="语音">
          <AudioRecorder v-model="phraseForm.audioUrl" />
        </el-form-item>
        <el-form-item label="配图">
          <ImageUpload v-model="phraseForm.imageUrl" />
        </el-form-item>
        <el-form-item label="排序">
          <el-input-number v-model="phraseForm.sortOrder" :min="0" :max="999" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="phraseDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSavePhrase">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
/**
 * CommBoard - 沟通板配置页面
 * 分类管理 + 常用语编辑（文字+语音）
 */
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Edit, Delete, Folder, View } from '@element-plus/icons-vue'
import PageHeader from '@/components/PageHeader.vue'
import ImageUpload from '@/components/ImageUpload.vue'
import AudioRecorder from '@/components/AudioRecorder.vue'
import {
  getCommCategories, createCommCategory, updateCommCategory, deleteCommCategory,
  getPhrases, createPhrase, updatePhrase, deletePhrase
} from '@/api/communication'

const categories = ref([])
const selectedCategory = ref(null)
const phrases = ref([])
const phrasesLoading = ref(false)

// 分类对话框
const catDialogVisible = ref(false)
const catDialogTitle = ref('新增分类')
const editingCatId = ref(null)
const catForm = reactive({ name: '', icon: '' })

// 常用语对话框
const phraseDialogVisible = ref(false)
const phraseDialogTitle = ref('添加常用语')
const editingPhraseId = ref(null)
const phraseForm = reactive({ text: '', audioUrl: '', imageUrl: '', sortOrder: 0 })

async function fetchCategories() {
  try {
    const res = await getCommCategories()
    categories.value = res.data || []
  } catch (error) {
    categories.value = [
      { id: '1', name: '日常问候', icon: 'greeting', phraseCount: 5 },
      { id: '2', name: '工作相关', icon: 'work', phraseCount: 8 },
      { id: '3', name: '情绪表达', icon: 'emotion', phraseCount: 6 },
      { id: '4', name: '饮食', icon: 'food', phraseCount: 4 }
    ]
  }
}

async function fetchPhrases(categoryId) {
  phrasesLoading.value = true
  try {
    const res = await getPhrases(categoryId)
    phrases.value = res.data || []
  } catch (error) {
    phrases.value = [
      { id: '1', text: '你好', audioUrl: '', imageUrl: '', sortOrder: 1 },
      { id: '2', text: '谢谢', audioUrl: '/audio/thanks.mp3', imageUrl: '', sortOrder: 2 },
      { id: '3', text: '我需要帮助', audioUrl: '', imageUrl: '/img/help.png', sortOrder: 3 }
    ]
  } finally {
    phrasesLoading.value = false
  }
}

function selectCategory(cat) {
  selectedCategory.value = cat
  fetchPhrases(cat.id)
}

function handleAddCategory() {
  editingCatId.value = null
  catDialogTitle.value = '新增分类'
  catForm.name = ''
  catForm.icon = ''
  catDialogVisible.value = true
}

function handleEditCategory(cat) {
  editingCatId.value = cat.id
  catDialogTitle.value = '编辑分类'
  catForm.name = cat.name
  catForm.icon = cat.icon
  catDialogVisible.value = true
}

async function handleSaveCategory() {
  if (!catForm.name) { ElMessage.warning('请输入分类名称'); return }
  try {
    if (editingCatId.value) {
      await updateCommCategory(editingCatId.value, catForm)
      ElMessage.success('更新成功')
    } else {
      await createCommCategory(catForm)
      ElMessage.success('创建成功')
    }
    catDialogVisible.value = false
    fetchCategories()
  } catch (error) { console.error('保存分类失败:', error) }
}

async function handleDeleteCategory(cat) {
  try {
    await ElMessageBox.confirm(`确定删除分类 "${cat.name}" 吗？`, '确认', { type: 'warning' })
    await deleteCommCategory(cat.id)
    ElMessage.success('删除成功')
    if (selectedCategory.value?.id === cat.id) selectedCategory.value = null
    fetchCategories()
  } catch (error) { if (error !== 'cancel') console.error(error) }
}

function handleAddPhrase() {
  editingPhraseId.value = null
  phraseDialogTitle.value = '添加常用语'
  Object.assign(phraseForm, { text: '', audioUrl: '', imageUrl: '', sortOrder: 0 })
  phraseDialogVisible.value = true
}

function handleEditPhrase(row) {
  editingPhraseId.value = row.id
  phraseDialogTitle.value = '编辑常用语'
  Object.assign(phraseForm, row)
  phraseDialogVisible.value = true
}

async function handleSavePhrase() {
  if (!phraseForm.text) { ElMessage.warning('请输入文字内容'); return }
  try {
    if (editingPhraseId.value) {
      await updatePhrase(selectedCategory.value.id, editingPhraseId.value, phraseForm)
      ElMessage.success('更新成功')
    } else {
      await createPhrase(selectedCategory.value.id, phraseForm)
      ElMessage.success('添加成功')
    }
    phraseDialogVisible.value = false
    fetchPhrases(selectedCategory.value.id)
  } catch (error) { console.error('保存常用语失败:', error) }
}

async function handleDeletePhrase(row) {
  try {
    await ElMessageBox.confirm('确定删除该常用语吗？', '确认', { type: 'warning' })
    await deletePhrase(selectedCategory.value.id, row.id)
    ElMessage.success('删除成功')
    fetchPhrases(selectedCategory.value.id)
  } catch (error) { if (error !== 'cancel') console.error(error) }
}

function handlePreview() {
  ElMessage.info('预览功能将在新窗口打开沟通板')
}

onMounted(() => { fetchCategories() })
</script>

<style scoped>
.comm-layout {
  display: grid;
  grid-template-columns: 280px 1fr;
  gap: 16px;
  align-items: start;
}

.section-title {
  margin: 0 0 12px;
  font-size: 15px;
  font-weight: 600;
  color: #303133;
}

/* 分类列表 */
.category-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 12px;
  border-radius: 6px;
  cursor: pointer;
  transition: background 0.2s;
  margin-bottom: 4px;
}

.category-item:hover {
  background: #f5f7fa;
}

.category-item--active {
  background: #ecf5ff;
  border-left: 3px solid #409EFF;
}

.category-name {
  flex: 1;
  font-size: 14px;
  color: #303133;
}

.category-count {
  font-size: 12px;
  color: #909399;
  background: #f0f0f0;
  padding: 1px 8px;
  border-radius: 10px;
}

.category-actions {
  display: none;
  gap: 0;
}

.category-item:hover .category-actions {
  display: flex;
}

/* 常用语面板 */
.phrases-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
}

.phrases-header .section-title {
  margin-bottom: 0;
}

.phrases-actions {
  display: flex;
  gap: 8px;
}

.text-placeholder {
  font-size: 12px;
  color: #C0C4CC;
}

.empty-panel {
  min-height: 300px;
  display: flex;
  align-items: center;
  justify-content: center;
}

@media screen and (max-width: 768px) {
  .comm-layout {
    grid-template-columns: 1fr;
  }
}
</style>
