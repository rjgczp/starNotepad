<template>
  <div class="gva-table-box duo-call-page">
    <el-alert title="Love Cottage 仅允许两个秘钥访问。修改秘钥后，对应用户的旧会话会立即失效。" type="info" :closable="false" show-icon />
    <el-tabs v-model="tab">
      <el-tab-pane label="双人秘钥" name="keys" />
      <el-tab-pane label="状态选项" name="status" />
      <el-tab-pane label="聊天记录" name="messages" />
      <el-tab-pane label="相册管理" name="albums" />
      <el-tab-pane label="纪念日" name="anniversaries" />
    </el-tabs>

    <section v-if="tab === 'keys'" class="cards">
      <el-card v-for="item in identities" :key="item.slot">
        <template #header>身份 {{ item.slot }}</template>
        <el-form label-position="top">
          <el-form-item label="显示名称"><el-input v-model="item.displayName" /></el-form-item>
          <el-form-item label="登录秘钥"><el-input v-model="item.key" show-password /></el-form-item>
          <el-form-item label="启用"><el-switch v-model="item.enabled" /></el-form-item>
          <el-button type="primary" :loading="saving" @click="saveIdentity(item)">保存身份 {{ item.slot }}</el-button>
        </el-form>
      </el-card>
    </section>

    <section v-else-if="tab === 'status'">
      <div class="gva-btn-list"><el-button type="primary" :icon="Plus" @click="addStatus">新增状态</el-button><el-button :icon="Refresh" @click="load">刷新</el-button></div>
      <el-table :data="statuses"><el-table-column label="名称"><template #default="{ row }"><el-input v-model="row.label" /></template></el-table-column><el-table-column label="Emoji" width="150"><template #default="{ row }"><el-input v-model="row.emoji" /></template></el-table-column><el-table-column label="排序" width="130"><template #default="{ row }"><el-input-number v-model="row.sort" :min="0" /></template></el-table-column><el-table-column label="启用" width="100"><template #default="{ row }"><el-switch v-model="row.enabled" /></template></el-table-column><el-table-column label="操作" width="160"><template #default="{ row }"><el-button type="primary" link @click="saveStatus(row)">保存</el-button><el-button v-if="row.ID" type="danger" link @click="removeStatus(row)">删除</el-button></template></el-table-column></el-table>
    </section>

    <section v-else-if="tab === 'messages'">
      <el-table :data="messages" max-height="600"><el-table-column prop="ID" label="ID" width="80" /><el-table-column prop="senderSlot" label="发送者" width="100"><template #default="{ row }">身份 {{ row.senderSlot }}</template></el-table-column><el-table-column label="内容" min-width="300"><template #default="{ row }"><el-image v-if="row.kind === 'image'" :src="row.imageUrl" fit="contain" style="width:80px;height:60px" preview-teleported :preview-src-list="[row.imageUrl]" /><span v-else>{{ row.content }}</span></template></el-table-column><el-table-column prop="CreatedAt" label="发送时间" width="190" /><el-table-column prop="readAt" label="已读时间" width="190"><template #default="{ row }">{{ row.readAt || '未读' }}</template></el-table-column></el-table>
    </section>

    <section v-else-if="tab === 'albums'">
      <el-alert title="相册图片由爱情小屋上传。这里可查看、调整上传用户与上传日期，或删除图片。" type="warning" :closable="false" show-icon class="mb-4" />
      <el-table :data="albums" max-height="620"><el-table-column label="预览" width="120"><template #default="{ row }"><el-image :src="row.imageUrl" fit="cover" style="width:78px;height:58px;border-radius:8px" preview-teleported :preview-src-list="[row.imageUrl]" /></template></el-table-column><el-table-column label="上传用户" width="150"><template #default="{ row }"><el-select v-model="row.uploaderSlot"><el-option :value="1" label="身份 1" /><el-option :value="2" label="身份 2" /></el-select></template></el-table-column><el-table-column label="上传日期" min-width="220"><template #default="{ row }"><el-date-picker v-model="row.uploadedAt" type="datetime" value-format="YYYY-MM-DD HH:mm:ss" /></template></el-table-column><el-table-column prop="CreatedAt" label="记录创建时间" width="190" /><el-table-column label="操作" width="160"><template #default="{ row }"><el-button type="primary" link @click="saveAlbum(row)">保存</el-button><el-button type="danger" link @click="removeAlbum(row)">删除</el-button></template></el-table-column></el-table>
    </section>

    <section v-else>
      <div class="gva-btn-list"><el-button type="primary" :icon="Plus" @click="addAnniversary">新增纪念日</el-button><el-button :icon="Refresh" @click="load">刷新</el-button></div>
      <el-table :data="anniversaries"><el-table-column label="名称" min-width="220"><template #default="{ row }"><el-input v-model="row.title" placeholder="例如：在一起纪念日" /></template></el-table-column><el-table-column label="日期" min-width="200"><template #default="{ row }"><el-date-picker v-model="row.date" type="date" value-format="YYYY-MM-DD" /></template></el-table-column><el-table-column label="排序" width="130"><template #default="{ row }"><el-input-number v-model="row.sort" :min="0" /></template></el-table-column><el-table-column label="启用" width="100"><template #default="{ row }"><el-switch v-model="row.enabled" /></template></el-table-column><el-table-column label="操作" width="160"><template #default="{ row }"><el-button type="primary" link @click="saveAnniversary(row)">保存</el-button><el-button v-if="row.ID" type="danger" link @click="removeAnniversary(row)">删除</el-button></template></el-table-column></el-table>
    </section>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { Plus, Refresh } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { deleteDuoAlbum, deleteDuoAnniversary, deleteDuoStatus, getDuoCallAdmin, saveDuoAlbum, saveDuoAnniversary, saveDuoIdentity, saveDuoStatus } from '@/api/system/duoCall'

defineOptions({ name: 'DuoCall' })
const tab = ref('keys'); const identities = ref([]); const statuses = ref([]); const messages = ref([]); const albums = ref([]); const anniversaries = ref([]); const saving = ref(false)
const asDateTimeValue = (value) => value ? new Date(value).toLocaleString('sv-SE').replace('T', ' ') : ''
const asDateValue = (value) => value ? new Date(value).toISOString().slice(0, 10) : ''
const load = async () => { const res = await getDuoCallAdmin(); if (res.code === 0) { identities.value = res.data.identities; statuses.value = res.data.statuses; messages.value = res.data.messages; albums.value = (res.data.albums || []).map((item) => ({ ...item, uploadedAt: asDateTimeValue(item.uploadedAt) })); anniversaries.value = (res.data.anniversaries || []).map((item) => ({ ...item, date: asDateValue(item.date) })) } }
const saveIdentity = async (item) => { saving.value = true; try { const res = await saveDuoIdentity(item); if (res.code === 0) { ElMessage.success('保存成功'); load() } } finally { saving.value = false } }
const addStatus = () => statuses.value.push({ label: '', emoji: '✨', enabled: true, sort: statuses.value.length * 10 + 10 })
const saveStatus = async (item) => { const res = await saveDuoStatus(item); if (res.code === 0) { ElMessage.success('保存成功'); load() } }
const removeStatus = async (item) => { await ElMessageBox.confirm(`删除状态“${item.label}”吗？`, '确认删除', { type: 'warning' }); const res = await deleteDuoStatus({ ID: item.ID }); if (res.code === 0) { ElMessage.success('已删除'); load() } }
const asISO = (value) => value ? new Date(value).toISOString() : ''
const saveAlbum = async (item) => { const res = await saveDuoAlbum({ ID: item.ID, uploaderSlot: item.uploaderSlot, uploadedAt: asISO(item.uploadedAt) }); if (res.code === 0) { ElMessage.success('相册信息已保存'); load() } }
const removeAlbum = async (item) => { await ElMessageBox.confirm('删除后图片会从爱情小屋和服务器中移除，确认继续吗？', '删除图片', { type: 'warning' }); const res = await deleteDuoAlbum({ ID: item.ID }); if (res.code === 0) { ElMessage.success('已删除'); load() } }
const addAnniversary = () => anniversaries.value.push({ title: '', date: '', enabled: true, sort: anniversaries.value.length * 10 + 10 })
const saveAnniversary = async (item) => { const res = await saveDuoAnniversary({ ...item, date: item.date ? new Date(`${item.date}T00:00:00`).toISOString() : '' }); if (res.code === 0) { ElMessage.success('纪念日已保存'); load() } }
const removeAnniversary = async (item) => { await ElMessageBox.confirm(`删除纪念日“${item.title}”吗？`, '确认删除', { type: 'warning' }); const res = await deleteDuoAnniversary({ ID: item.ID }); if (res.code === 0) { ElMessage.success('已删除'); load() } }
load()
</script>

<style scoped>
.duo-call-page{padding-top:20px}.duo-call-page :deep(.el-tabs){margin-top:18px}.duo-call-page section{margin-top:20px}.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:20px}
</style>
