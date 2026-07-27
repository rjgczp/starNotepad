<template>
  <div class="gva-table-box blog-content-page">
    <el-alert title="博客前端只展示已发布文章和已启用的技能、项目、工作经历。中英文内容可分别填写，留空的英文会回退显示中文。" type="info" :closable="false" show-icon />
    <el-tabs v-model="activeKind" @tab-change="resetForm">
      <el-tab-pane label="文章" name="post" />
      <el-tab-pane label="技能 / 技术栈" name="skill" />
      <el-tab-pane label="项目" name="project" />
      <el-tab-pane label="工作经历" name="experience" />
    </el-tabs>
    <div class="gva-btn-list"><el-button type="primary" :icon="Plus" @click="openCreate">新增{{ kindLabel }}</el-button><el-button :icon="Refresh" @click="load">刷新</el-button></div>
    <el-table v-loading="loading" :data="items" row-key="ID">
      <el-table-column label="主标题" min-width="220"><template #default="{ row }">{{ row.titleZh || row.name || row.period }}</template></el-table-column>
      <el-table-column v-if="activeKind === 'post'" prop="slug" label="Slug" min-width="180" />
      <el-table-column v-if="activeKind === 'post'" label="发布" width="100"><template #default="{ row }"><el-tag :type="row.published ? 'success' : 'info'">{{ row.published ? '已发布' : '草稿' }}</el-tag></template></el-table-column>
      <el-table-column v-if="activeKind !== 'post'" label="状态" width="100"><template #default="{ row }"><el-tag :type="row.enabled ? 'success' : 'info'">{{ row.enabled ? '已启用' : '已停用' }}</el-tag></template></el-table-column>
      <el-table-column prop="sort" label="排序" width="80" />
      <el-table-column label="操作" width="160" fixed="right"><template #default="{ row }"><el-button type="primary" link :icon="Edit" @click="openEdit(row)">编辑</el-button><el-button type="danger" link :icon="Delete" @click="remove(row)">删除</el-button></template></el-table-column>
    </el-table>

    <el-dialog v-model="dialog" :title="form.ID ? `编辑${kindLabel}` : `新增${kindLabel}`" width="760px" destroy-on-close>
      <el-form :model="form" label-position="top">
        <template v-if="activeKind === 'post'"><el-form-item label="Slug"><el-input v-model="form.slug" placeholder="例如 first-post" /></el-form-item><el-form-item label="中文标题"><el-input v-model="form.titleZh" /></el-form-item><el-form-item label="英文标题"><el-input v-model="form.titleEn" /></el-form-item><el-form-item label="中文摘要"><el-input v-model="form.excerptZh" type="textarea" :rows="2" /></el-form-item><el-form-item label="英文摘要"><el-input v-model="form.excerptEn" type="textarea" :rows="2" /></el-form-item><el-form-item label="中文正文（支持 HTML）"><el-input v-model="form.contentZh" type="textarea" :rows="7" /></el-form-item><el-form-item label="英文正文（支持 HTML）"><el-input v-model="form.contentEn" type="textarea" :rows="7" /></el-form-item><el-form-item label="标签（JSON 数组）"><el-input v-model="form.tagsText" placeholder='["Next.js", "设计"]' /></el-form-item><el-form-item label="发布时间"><el-date-picker v-model="form.publishedAt" type="datetime" value-format="YYYY-MM-DDTHH:mm:ssZ" /></el-form-item><el-form-item label="发布"><el-switch v-model="form.published" /></el-form-item></template>
        <template v-else-if="activeKind === 'skill'"><el-form-item label="技术名称"><el-input v-model="form.name" /></el-form-item><el-form-item label="中文说明"><el-input v-model="form.descriptionZh" type="textarea" /></el-form-item><el-form-item label="英文说明"><el-input v-model="form.descriptionEn" type="textarea" /></el-form-item><el-form-item label="熟练度"><el-input-number v-model="form.level" :min="0" :max="100" /></el-form-item><el-form-item label="启用"><el-switch v-model="form.enabled" /></el-form-item></template>
        <template v-else-if="activeKind === 'project'"><el-form-item label="项目名称"><el-input v-model="form.name" /></el-form-item><el-form-item label="项目链接"><el-input v-model="form.link" /></el-form-item><el-form-item label="中文说明"><el-input v-model="form.descriptionZh" type="textarea" /></el-form-item><el-form-item label="英文说明"><el-input v-model="form.descriptionEn" type="textarea" /></el-form-item><el-form-item label="标签（JSON 数组）"><el-input v-model="form.tagsText" /></el-form-item><el-form-item label="启用"><el-switch v-model="form.enabled" /></el-form-item></template>
        <template v-else><el-form-item label="时间段"><el-input v-model="form.period" placeholder="2024 — 至今" /></el-form-item><el-form-item label="中文职位"><el-input v-model="form.titleZh" /></el-form-item><el-form-item label="英文职位"><el-input v-model="form.titleEn" /></el-form-item><el-form-item label="中文组织"><el-input v-model="form.organizationZh" /></el-form-item><el-form-item label="英文组织"><el-input v-model="form.organizationEn" /></el-form-item><el-form-item label="中文描述"><el-input v-model="form.descriptionZh" type="textarea" /></el-form-item><el-form-item label="英文描述"><el-input v-model="form.descriptionEn" type="textarea" /></el-form-item><el-form-item label="启用"><el-switch v-model="form.enabled" /></el-form-item></template>
        <el-form-item label="排序"><el-input-number v-model="form.sort" :min="0" :max="9999" /></el-form-item>
      </el-form>
      <template #footer><el-button @click="dialog = false">取消</el-button><el-button type="primary" :loading="saving" @click="save">保存</el-button></template>
    </el-dialog>
  </div>
</template>

<script setup>
import { computed, reactive, ref } from 'vue'
import { Delete, Edit, Plus, Refresh } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { createBlogItem, deleteBlogItem, getBlogContent, updateBlogItem } from '@/api/system/blogContent'

defineOptions({ name: 'BlogContent' })
const activeKind = ref('post'); const loading = ref(false); const saving = ref(false); const dialog = ref(false)
const data = reactive({ posts: [], skills: [], projects: [], experiences: [] })
const labels = { post: '文章', skill: '技能', project: '项目', experience: '工作经历' }
const kindLabel = computed(() => labels[activeKind.value])
const items = computed(() => data[`${activeKind.value}s`] || [])
const blank = () => ({ ID: 0, slug: '', titleZh: '', titleEn: '', excerptZh: '', excerptEn: '', contentZh: '', contentEn: '', tagsText: '[]', published: false, publishedAt: '', name: '', descriptionZh: '', descriptionEn: '', link: '', period: '', organizationZh: '', organizationEn: '', enabled: true, level: 0, sort: 0 })
const form = reactive(blank())
const resetForm = () => Object.assign(form, blank())
const load = async () => { loading.value = true; try { const res = await getBlogContent(); if (res.code === 0) Object.assign(data, res.data) } finally { loading.value = false } }
const openCreate = () => { resetForm(); form.sort = items.value.length * 10 + 10; dialog.value = true }
const openEdit = row => { resetForm(); Object.assign(form, row, { tagsText: JSON.stringify(row.tags || []) }); dialog.value = true }
const parseTags = () => { try { const tags = JSON.parse(form.tagsText || '[]'); return Array.isArray(tags) ? tags : [] } catch { ElMessage.warning('标签必须是 JSON 数组'); return null } }
const save = async () => { const tags = activeKind.value === 'post' || activeKind.value === 'project' ? parseTags() : []; if (tags === null) return; if (activeKind.value === 'post' && (!form.slug || !form.titleZh)) return ElMessage.warning('请填写 Slug 和中文标题'); saving.value = true; try { const payload = { ...form, tags }; delete payload.tagsText; const res = await (form.ID ? updateBlogItem : createBlogItem)(activeKind.value, payload); if (res.code === 0) { ElMessage.success('保存成功'); dialog.value = false; await load() } } finally { saving.value = false } }
const remove = async row => { await ElMessageBox.confirm(`确定删除此${kindLabel.value}吗？`, '删除确认', { type: 'warning' }); const res = await deleteBlogItem({ kind: activeKind.value, ID: row.ID }); if (res.code === 0) { ElMessage.success('删除成功'); await load() } }
load()
</script>

<style scoped>
.blog-content-page { padding-top: 20px; }
.blog-content-page :deep(.el-tabs) { margin-top: 18px; }
.blog-content-page :deep(.gva-btn-list) { margin-top: 18px; }
</style>
