<template>
  <div class="gva-table-box">
    <div class="gva-btn-list">
      <el-button type="primary" :icon="Plus" @click="openCreate">新增图片</el-button>
      <el-button :icon="Refresh" @click="loadImages">刷新</el-button>
    </div>

    <el-alert
      class="mb-4"
      title="已启用的图片会按排序值从小到大显示在个人主页彩蛋中。"
      type="info"
      :closable="false"
      show-icon
    />

    <el-table v-loading="loading" :data="images" row-key="ID">
      <el-table-column label="预览" width="120">
        <template #default="scope">
          <el-image
            class="h-18 w-18 rounded object-cover"
            :src="scope.row.url"
            :preview-src-list="[scope.row.url]"
            preview-teleported
            fit="cover"
          />
        </template>
      </el-table-column>
      <el-table-column prop="name" label="名称" min-width="160" />
      <el-table-column prop="url" label="图片地址" min-width="300" show-overflow-tooltip />
      <el-table-column prop="sort" label="排序" width="100" />
      <el-table-column label="状态" width="100">
        <template #default="scope">
          <el-tag :type="scope.row.enabled ? 'success' : 'info'">
            {{ scope.row.enabled ? '已启用' : '已停用' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" fixed="right" width="180">
        <template #default="scope">
          <el-button type="primary" link :icon="Edit" @click="openEdit(scope.row)">编辑</el-button>
          <el-button type="danger" link :icon="Delete" @click="removeImage(scope.row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-empty v-if="!loading && images.length === 0" description="暂无彩蛋图片，请点击新增图片" />

    <el-dialog v-model="dialogVisible" :title="form.ID ? '编辑图片' : '新增图片'" width="560px" destroy-on-close>
      <el-form ref="formRef" :model="form" :rules="rules" label-width="90px">
        <el-form-item label="图片" prop="url">
          <div class="flex items-center gap-4">
            <el-image v-if="form.url" class="h-24 w-24 rounded" :src="form.url" fit="cover" />
            <UploadImage @on-success="handleUploadSuccess" />
          </div>
        </el-form-item>
        <el-form-item label="图片地址" prop="url">
          <el-input v-model="form.url" placeholder="上传图片或输入 URL" />
        </el-form-item>
        <el-form-item label="名称">
          <el-input v-model="form.name" placeholder="便于后台识别，可选" />
        </el-form-item>
        <el-form-item label="排序">
          <el-input-number v-model="form.sort" :min="0" :max="9999" />
        </el-form-item>
        <el-form-item label="启用">
          <el-switch v-model="form.enabled" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="saveImage">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import { Delete, Edit, Plus, Refresh } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import UploadImage from '@/components/upload/image.vue'
import { createMainImage, deleteMainImage, getMainImages, updateMainImage } from '@/api/system/mainImage'

defineOptions({ name: 'MainImg' })

const images = ref([])
const loading = ref(false)
const saving = ref(false)
const dialogVisible = ref(false)
const formRef = ref()
const form = reactive({ ID: 0, name: '', url: '', sort: 0, enabled: true })
const rules = { url: [{ required: true, message: '请上传图片或填写图片地址', trigger: 'blur' }] }

const resetForm = () => Object.assign(form, { ID: 0, name: '', url: '', sort: 0, enabled: true })

const loadImages = async () => {
  loading.value = true
  try {
    const res = await getMainImages()
    if (res.code === 0) images.value = Array.isArray(res.data) ? res.data : []
  } finally {
    loading.value = false
  }
}

const openCreate = () => {
  resetForm()
  form.sort = images.value.length ? Math.max(...images.value.map(item => Number(item.sort) || 0)) + 10 : 10
  dialogVisible.value = true
}

const openEdit = (row) => {
  Object.assign(form, { ID: row.ID, name: row.name || '', url: row.url || '', sort: row.sort || 0, enabled: Boolean(row.enabled) })
  dialogVisible.value = true
}

const handleUploadSuccess = (url) => {
  const normalized = url.startsWith('/') ? url : `/${url}`
  form.url = normalized.startsWith('/uploads/') ? `/api${normalized}` : normalized
}

const saveImage = async () => {
  await formRef.value?.validate()
  saving.value = true
  try {
    const action = form.ID ? updateMainImage : createMainImage
    const res = await action({ ...form })
    if (res.code === 0) {
      ElMessage.success('保存成功')
      dialogVisible.value = false
      await loadImages()
    }
  } finally {
    saving.value = false
  }
}

const removeImage = async (row) => {
  await ElMessageBox.confirm(`确定删除“${row.name || '该图片'}”吗？`, '删除确认', { type: 'warning' })
  const res = await deleteMainImage({ ID: row.ID })
  if (res.code === 0) {
    ElMessage.success('删除成功')
    await loadImages()
  }
}

onMounted(loadImages)
</script>
