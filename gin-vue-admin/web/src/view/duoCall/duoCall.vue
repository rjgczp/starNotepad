<template>
  <div class="gva-table-box duo-call-page">
    <el-alert title="Love Cottage 仅允许两个秘钥访问。修改秘钥后，对应用户的旧会话会立即失效。" type="info" :closable="false" show-icon />
    <el-tabs v-model="tab">
      <el-tab-pane label="双人秘钥" name="keys" />
      <el-tab-pane label="应用发版" name="releases" />
      <el-tab-pane label="状态选项" name="status" />
      <el-tab-pane label="聊天记录" name="messages" />
      <el-tab-pane label="相册管理" name="albums" />
      <el-tab-pane label="纪念日" name="anniversaries" />
      <el-tab-pane label="每日回信" name="daily" />
      <el-tab-pane label="微信推送" name="wechat" />
      <el-tab-pane label="推送队列" name="push" />
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

    <section v-else-if="tab === 'releases'" class="release-section">
      <el-alert title="发布后，爱情小屋启动时会检查对应平台的版本。勾选“强制更新”后，用户只能下载新版后再继续使用。" type="warning" :closable="false" show-icon class="mb-4" />
      <el-card class="release-editor">
        <template #header>{{ releaseDraft.ID ? '编辑发布版' : '新增发布版' }}</template>
        <el-form :model="releaseDraft" label-position="top" class="release-form">
          <el-form-item label="平台"><el-select v-model="releaseDraft.platform"><el-option v-for="item in releasePlatforms" :key="item.value" :label="item.label" :value="item.value" /></el-select></el-form-item>
          <el-form-item label="版本号"><el-input v-model="releaseDraft.version" placeholder="例如 1.2.0" /></el-form-item>
          <el-form-item label="下载地址"><el-input v-model="releaseDraft.downloadUrl" placeholder="上传安装包后自动填入，也可填写 HTTPS 地址" /></el-form-item>
          <el-form-item label="安装包文件">
            <el-upload
              :action="releaseUploadAction"
              :accept="releaseUploadAccept"
              :data="{ platform: releaseDraft.platform }"
              :headers="{ 'x-token': userStore.token }"
              :show-file-list="false"
              :before-upload="beforeReleaseUpload"
              :on-success="handleReleaseUploadSuccess"
              :on-error="handleReleaseUploadError"
              :disabled="releaseUploading"
            >
              <el-button type="primary" :loading="releaseUploading">上传安装包</el-button>
            </el-upload>
            <span v-if="releaseUploadName" class="release-upload-name">已上传：{{ releaseUploadName }}</span>
            <span class="release-upload-hint">Android 支持 APK/AAB；桌面端支持 DMG、MSI、EXE 等，单个文件最大 512MB。</span>
          </el-form-item>
          <el-form-item label="更新说明"><el-input v-model="releaseDraft.releaseNotes" type="textarea" :rows="3" placeholder="告诉用户本次更新了什么" /></el-form-item>
          <el-form-item label="发布设置"><el-switch v-model="releaseDraft.published" active-text="立即发布" inactive-text="保存为草稿" /><el-switch v-model="releaseDraft.forceUpdate" active-text="强制更新" inactive-text="可稍后更新" class="release-force-switch" /></el-form-item>
          <el-button type="primary" @click="saveRelease(releaseDraft)">保存发布版</el-button><el-button v-if="releaseDraft.ID" @click="releaseDraft = emptyRelease()">取消编辑</el-button>
        </el-form>
      </el-card>
      <el-table :data="releases" max-height="560" class="release-table">
        <el-table-column prop="platform" label="平台" width="100" />
        <el-table-column prop="version" label="版本" width="130" />
        <el-table-column label="状态" width="130"><template #default="{ row }"><el-tag :type="row.published ? 'success' : 'info'">{{ row.published ? '已发布' : '草稿' }}</el-tag><el-tag v-if="row.forceUpdate" type="danger" class="ml-1">强制</el-tag></template></el-table-column>
        <el-table-column prop="downloadUrl" label="下载地址" min-width="260" show-overflow-tooltip />
        <el-table-column prop="releaseNotes" label="更新说明" min-width="220" show-overflow-tooltip />
        <el-table-column prop="publishedAt" label="发布时间" width="180" />
        <el-table-column label="操作" width="150"><template #default="{ row }"><el-button type="primary" link @click="editRelease(row)">编辑</el-button><el-button type="danger" link @click="removeRelease(row)">删除</el-button></template></el-table-column>
      </el-table>
    </section>

    <section v-else-if="tab === 'status'">
      <div class="gva-btn-list">
        <el-button type="primary" :icon="Plus" @click="addStatus">新增状态</el-button>
        <el-button :icon="Refresh" @click="load">刷新</el-button>
      </div>
      <el-table :data="statuses">
        <el-table-column label="名称"><template #default="{ row }"><el-input v-model="row.label" /></template></el-table-column>
        <el-table-column label="Emoji" width="150"><template #default="{ row }"><el-input v-model="row.emoji" /></template></el-table-column>
        <el-table-column label="排序" width="130"><template #default="{ row }"><el-input-number v-model="row.sort" :min="0" /></template></el-table-column>
        <el-table-column label="启用" width="100"><template #default="{ row }"><el-switch v-model="row.enabled" /></template></el-table-column>
        <el-table-column label="操作" width="160"><template #default="{ row }"><el-button type="primary" link @click="saveStatus(row)">保存</el-button><el-button v-if="row.ID" type="danger" link @click="removeStatus(row)">删除</el-button></template></el-table-column>
      </el-table>
    </section>

    <section v-else-if="tab === 'messages'">
      <el-table :data="messages" max-height="600">
        <el-table-column prop="ID" label="ID" width="80" />
        <el-table-column prop="senderSlot" label="发送者" width="100"><template #default="{ row }">身份 {{ row.senderSlot }}</template></el-table-column>
        <el-table-column label="内容" min-width="300"><template #default="{ row }"><el-image v-if="row.kind === 'image'" :src="row.imageUrl" fit="contain" class="message-preview" preview-teleported :preview-src-list="[row.imageUrl]" /><span v-else>{{ row.content }}</span></template></el-table-column>
        <el-table-column prop="CreatedAt" label="发送时间" width="190" />
        <el-table-column prop="readAt" label="已读时间" width="190"><template #default="{ row }">{{ row.readAt || '未读' }}</template></el-table-column>
      </el-table>
    </section>

    <section v-else-if="tab === 'albums'">
      <el-alert title="相册图片由爱情小屋上传。这里可查看、调整上传用户与上传日期，或删除图片。" type="warning" :closable="false" show-icon class="mb-4" />
      <el-table :data="albums" max-height="620">
        <el-table-column label="预览" width="120"><template #default="{ row }"><el-image :src="row.imageUrl" fit="cover" class="album-preview" preview-teleported :preview-src-list="[row.imageUrl]" /></template></el-table-column>
        <el-table-column label="上传用户" width="150"><template #default="{ row }"><el-select v-model="row.uploaderSlot"><el-option :value="1" label="身份 1" /><el-option :value="2" label="身份 2" /></el-select></template></el-table-column>
        <el-table-column label="上传日期" min-width="220"><template #default="{ row }"><el-date-picker v-model="row.uploadedAt" type="datetime" value-format="YYYY-MM-DD HH:mm:ss" /></template></el-table-column>
        <el-table-column prop="CreatedAt" label="记录创建时间" width="190" />
        <el-table-column label="操作" width="160"><template #default="{ row }"><el-button type="primary" link @click="saveAlbum(row)">保存</el-button><el-button type="danger" link @click="removeAlbum(row)">删除</el-button></template></el-table-column>
      </el-table>
    </section>

    <section v-else-if="tab === 'anniversaries'">
      <div class="gva-btn-list">
        <el-button type="primary" :icon="Plus" @click="addAnniversary">新增纪念日</el-button>
        <el-button :icon="Refresh" @click="load">刷新</el-button>
      </div>
      <el-table :data="anniversaries">
        <el-table-column label="名称" min-width="220"><template #default="{ row }"><el-input v-model="row.title" placeholder="例如：在一起纪念日" /></template></el-table-column>
        <el-table-column label="日期" min-width="200"><template #default="{ row }"><el-date-picker v-model="row.date" type="date" value-format="YYYY-MM-DD" /></template></el-table-column>
        <el-table-column label="排序" width="130"><template #default="{ row }"><el-input-number v-model="row.sort" :min="0" /></template></el-table-column>
        <el-table-column label="启用" width="100"><template #default="{ row }"><el-switch v-model="row.enabled" /></template></el-table-column>
        <el-table-column label="操作" width="160"><template #default="{ row }"><el-button type="primary" link @click="saveAnniversary(row)">保存</el-button><el-button v-if="row.ID" type="danger" link @click="removeAnniversary(row)">删除</el-button></template></el-table-column>
      </el-table>
    </section>

    <section v-else-if="tab === 'daily'" class="ritual-layout">
      <el-alert title="每天 08:00（Asia/Shanghai）生成或沿用问题；仅在晚间 19:00、20:00、21:30、23:00 提醒尚未回复的身份，回复后立即停止后续提醒。" type="info" :closable="false" show-icon />
      <el-card>
        <template #header><div class="card-header"><span>每日生成设置</span><el-button type="primary" :loading="saving" @click="persistDailySetting">保存并重载定时任务</el-button></div></template>
        <el-form v-if="dailySetting" label-position="top" class="setting-grid">
          <el-form-item label="启用"><el-switch v-model="dailySetting.enabled" /></el-form-item>
          <el-form-item label="时区"><el-input v-model="dailySetting.timezone" /></el-form-item>
          <el-form-item label="每日时间（固定）"><el-time-picker v-model="dailySetting.generateTime" value-format="HH:mm" format="HH:mm" disabled /></el-form-item>
          <el-form-item label="近期回看天数"><el-input-number v-model="dailySetting.recentLookbackDays" :min="1" :max="365" /></el-form-item>
          <el-form-item label="相似度阈值"><el-input-number v-model="dailySetting.similarityThreshold" :min="0.5" :max="1" :step="0.01" /></el-form-item>
          <el-form-item label="问题字数上限"><el-input-number v-model="dailySetting.maxQuestionRunes" :min="10" :max="200" /></el-form-item>
          <el-form-item label="AI 重试次数"><el-input-number v-model="dailySetting.aiRetries" :min="0" :max="5" /></el-form-item>
        </el-form>
      </el-card>
      <el-card>
        <template #header><span>最近周期与提醒</span></template>
        <el-table :data="dailyCycles" max-height="240">
          <el-table-column prop="cycleDate" label="周期日期" width="140" />
          <el-table-column prop="questionId" label="问题 ID" width="100" />
          <el-table-column prop="status" label="周期状态" width="120" />
          <el-table-column prop="completedAt" label="完成时间" min-width="190" />
          <el-table-column prop="error" label="错误" min-width="220" />
        </el-table>
        <el-table :data="dailyReminders" max-height="280" class="reminder-table">
          <el-table-column prop="cycleDate" label="提醒日期" width="140" />
          <el-table-column prop="questionId" label="问题 ID" width="100" />
          <el-table-column prop="slot" label="身份" width="80" />
          <el-table-column prop="status" label="状态" width="110" />
          <el-table-column prop="sentCount" label="已提醒" width="90" />
          <el-table-column prop="nextReminderAt" label="下次时间" min-width="190" />
        </el-table>
      </el-card>
      <el-card>
        <template #header><div class="card-header"><span>最近生成</span><el-button type="warning" @click="regenerateDaily">重新生成今天的问题</el-button></div></template>
        <el-table :data="dailyQuestions" max-height="300">
          <el-table-column prop="questionDate" label="日期" width="170" />
          <el-table-column prop="question" label="问题" min-width="300" />
          <el-table-column prop="category" label="分类" width="120" />
          <el-table-column prop="source" label="来源" width="90" />
          <el-table-column label="状态" width="100"><template #default="{ row }">{{ row.revealedAt ? '已揭晓' : '进行中' }}</template></el-table-column>
        </el-table>
      </el-card>
      <el-card>
        <template #header><div class="card-header"><span>安全备用题库</span><el-button :icon="Plus" type="primary" @click="addFallback">新增问题</el-button></div></template>
        <el-table :data="fallbacks">
          <el-table-column label="问题" min-width="320"><template #default="{ row }"><el-input v-model="row.question" /></template></el-table-column>
          <el-table-column label="分类" width="170"><template #default="{ row }"><el-select v-model="row.category"><el-option v-for="category in categories" :key="category" :label="category" :value="category" /></el-select></template></el-table-column>
          <el-table-column label="启用" width="90"><template #default="{ row }"><el-switch v-model="row.enabled" /></template></el-table-column>
          <el-table-column prop="useCount" label="使用次数" width="100" />
          <el-table-column label="操作" width="150"><template #default="{ row }"><el-button type="primary" link @click="persistFallback(row)">保存</el-button><el-button v-if="row.ID" type="danger" link @click="removeFallback(row)">删除</el-button></template></el-table-column>
        </el-table>
      </el-card>
    </section>

    <section v-else-if="tab === 'wechat'">
      <el-alert :title="wechatHealthText" :type="wechatHealthReady ? 'success' : 'warning'" :closable="false" show-icon />
      <div class="cards recipient-cards">
        <el-card v-for="recipient in recipients" :key="recipient.slot">
          <template #header>身份 {{ recipient.slot }} · {{ recipient.openIdMasked || '未绑定' }}</template>
          <el-form label-position="top">
            <el-form-item label="新的 OpenID（留空保持原绑定）"><el-input v-model="recipient.openId" show-password autocomplete="off" /></el-form-item>
            <el-form-item label="启用推送"><el-switch v-model="recipient.enabled" /></el-form-item>
            <el-form-item v-for="field in recipientModeFields" :key="field.key" :label="field.label">
              <el-select v-model="recipient[field.key]"><el-option v-for="mode in pushModes" :key="mode.value" :label="mode.label" :value="mode.value" /></el-select>
            </el-form-item>
            <el-button type="primary" @click="persistRecipient(recipient)">保存绑定</el-button>
            <el-button :disabled="!recipient.enabled" @click="testRecipient(recipient)">发送测试（按聊天模式）</el-button>
            <el-button v-if="recipient.openIdMasked" type="danger" link @click="clearRecipient(recipient)">清除 OpenID</el-button>
          </el-form>
        </el-card>
      </div>
    </section>

    <section v-else>
      <div class="gva-btn-list">
        <el-select v-model="pushStatusFilter" clearable placeholder="筛选状态" class="push-filter"><el-option v-for="status in ['pending', 'processing', 'sent', 'failed']" :key="status" :label="status" :value="status" /></el-select>
        <el-button :icon="Refresh" @click="loadRitual">刷新队列</el-button>
      </div>
      <el-table :data="filteredPushOutbox" max-height="680">
        <el-table-column prop="ID" label="ID" width="80" />
        <el-table-column prop="eventType" label="事件" width="160" />
        <el-table-column prop="recipientSlot" label="身份" width="80" />
        <el-table-column prop="privacyMode" label="隐私模式" width="150" />
        <el-table-column prop="status" label="状态" width="110" />
        <el-table-column prop="attempts" label="尝试" width="80" />
        <el-table-column prop="lastError" label="失败原因（已脱敏）" min-width="260" />
        <el-table-column prop="CreatedAt" label="创建时间" width="190" />
        <el-table-column label="操作" width="100"><template #default="{ row }"><el-button v-if="row.status === 'failed'" type="primary" link @click="retryPush(row)">重试</el-button></template></el-table-column>
      </el-table>
    </section>
  </div>
</template>

<script setup>
import { computed, ref } from 'vue'
import { Plus, Refresh } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getBaseUrl } from '@/utils/format'
import { useUserStore } from '@/pinia'
import {
  deleteDuoAlbum, deleteDuoAnniversary, deleteDuoAppRelease, deleteDuoFallback, deleteDuoStatus,
  getDuoCallAdmin, getDuoRitualAdmin, regenerateDuoDaily, retryDuoWechatPush,
  saveDuoAlbum, saveDuoAnniversary, saveDuoAppRelease, saveDuoDailySetting, saveDuoFallback,
  saveDuoIdentity, saveDuoStatus, saveDuoWechatRecipient, testDuoWechatRecipient
} from '@/api/system/duoCall'

defineOptions({ name: 'DuoCall' })
const tab = ref('keys')
const saving = ref(false)
const identities = ref([])
const statuses = ref([])
const messages = ref([])
const albums = ref([])
const anniversaries = ref([])
const releases = ref([])
const userStore = useUserStore()
const releaseUploadAction = `${getBaseUrl()}/duoCall/admin/release/upload`
const releaseUploading = ref(false)
const releaseUploadName = ref('')
const releasePlatforms = [
  { label: '网页版', value: 'web' },
  { label: 'Android', value: 'android' },
  { label: '桌面端', value: 'desktop' }
]
const emptyRelease = () => ({ platform: 'android', version: '', downloadUrl: '', releaseNotes: '', published: false, forceUpdate: false })
const releaseDraft = ref(emptyRelease())
const releaseUploadAccept = computed(() => {
  if (releaseDraft.value.platform === 'android') return '.apk,.aab'
  if (releaseDraft.value.platform === 'desktop') return '.dmg,.msi,.exe,.pkg,.appimage,.deb,.rpm,.zip'
  return '.zip,.tar,.gz'
})
const dailySetting = ref(null)
const dailyQuestions = ref([])
const dailyCycles = ref([])
const dailyReminders = ref([])
const fallbacks = ref([])
const recipients = ref([])
const pushOutbox = ref([])
const pushStatusFilter = ref('')
const wechat = ref({})
const categories = ['daily', 'gratitude', 'future', 'understanding', 'memory', 'care', 'fun']
const pushModes = [
  { label: '仅提醒（推荐）', value: 'notification-only' },
  { label: '显示内容', value: 'full-content' },
  { label: '关闭', value: 'disabled' }
]
const recipientModeFields = [
  { key: 'dailyMode', label: '每日问题' },
  { key: 'chatMode', label: '聊天消息' },
  { key: 'replyMode', label: '伙伴已回答' },
  { key: 'revealMode', label: '共同揭晓' }
]
const wechatHealthReady = computed(() => Boolean(wechat.value.enabled && wechat.value.appIdConfigured && wechat.value.secretConfigured && wechat.value.templateConfigured && wechat.value.publicBaseUrl))
const wechatHealthText = computed(() => wechatHealthReady.value ? '微信测试号配置完整，推送 worker 已启用。' : '微信推送尚未完全启用，请检查环境变量、测试号模板和公网回跳地址。')
const filteredPushOutbox = computed(() => pushStatusFilter.value ? pushOutbox.value.filter(item => item.status === pushStatusFilter.value) : pushOutbox.value)

const asDateTimeValue = (value) => value ? new Date(value).toLocaleString('sv-SE').replace('T', ' ') : ''
const asDateValue = (value) => value ? new Date(value).toISOString().slice(0, 10) : ''
const asISO = (value) => value ? new Date(value).toISOString() : ''
const loadRitual = async () => {
  const res = await getDuoRitualAdmin()
  if (res.code !== 0) return
  dailySetting.value = res.data.setting
  dailyQuestions.value = res.data.questions || []
  dailyCycles.value = res.data.cycles || []
  dailyReminders.value = res.data.reminders || []
  fallbacks.value = res.data.fallbacks || []
  recipients.value = (res.data.recipients || []).map(item => ({ ...item, openId: '' }))
  pushOutbox.value = res.data.outbox || []
  wechat.value = res.data.wechat || {}
}
const load = async () => {
  const res = await getDuoCallAdmin()
  if (res.code === 0) {
    identities.value = res.data.identities
    statuses.value = res.data.statuses
    messages.value = res.data.messages
    albums.value = (res.data.albums || []).map(item => ({ ...item, uploadedAt: asDateTimeValue(item.uploadedAt) }))
    anniversaries.value = (res.data.anniversaries || []).map(item => ({ ...item, date: asDateValue(item.date) }))
    releases.value = res.data.releases || []
  }
  await loadRitual()
}
const saveIdentity = async (item) => { saving.value = true; try { const res = await saveDuoIdentity(item); if (res.code === 0) { ElMessage.success('保存成功'); load() } } finally { saving.value = false } }
const addStatus = () => statuses.value.push({ label: '', emoji: '✨', enabled: true, sort: statuses.value.length * 10 + 10 })
const saveStatus = async (item) => { const res = await saveDuoStatus(item); if (res.code === 0) { ElMessage.success('保存成功'); load() } }
const removeStatus = async (item) => { await ElMessageBox.confirm(`删除状态“${item.label}”吗？`, '确认删除', { type: 'warning' }); const res = await deleteDuoStatus({ ID: item.ID }); if (res.code === 0) { ElMessage.success('已删除'); load() } }
const saveAlbum = async (item) => { const res = await saveDuoAlbum({ ID: item.ID, uploaderSlot: item.uploaderSlot, uploadedAt: asISO(item.uploadedAt) }); if (res.code === 0) { ElMessage.success('相册信息已保存'); load() } }
const removeAlbum = async (item) => { await ElMessageBox.confirm('删除后图片会从爱情小屋和服务器中移除，确认继续吗？', '删除图片', { type: 'warning' }); const res = await deleteDuoAlbum({ ID: item.ID }); if (res.code === 0) { ElMessage.success('已删除'); load() } }
const addAnniversary = () => anniversaries.value.push({ title: '', date: '', enabled: true, sort: anniversaries.value.length * 10 + 10 })
const saveAnniversary = async (item) => { const res = await saveDuoAnniversary({ ...item, date: item.date ? new Date(`${item.date}T00:00:00`).toISOString() : '' }); if (res.code === 0) { ElMessage.success('纪念日已保存'); load() } }
const removeAnniversary = async (item) => { await ElMessageBox.confirm(`删除纪念日“${item.title}”吗？`, '确认删除', { type: 'warning' }); const res = await deleteDuoAnniversary({ ID: item.ID }); if (res.code === 0) { ElMessage.success('已删除'); load() } }
const editRelease = (item) => { releaseDraft.value = { ...item } }
const beforeReleaseUpload = (file) => {
  const extension = `.${file.name.split('.').pop()?.toLowerCase() || ''}`
  if (!releaseUploadAccept.value.split(',').includes(extension)) {
    ElMessage.error(`当前平台不支持 ${extension || '此'} 文件`)
    return false
  }
  if (!file.size || file.size > 512 * 1024 * 1024) {
    ElMessage.error('安装包必须大于 0 且不超过 512MB')
    return false
  }
  releaseUploading.value = true
  return true
}
const handleReleaseUploadSuccess = (response) => {
  releaseUploading.value = false
  if (response?.code !== 0 || !response.data?.url) {
    ElMessage.error(response?.msg || '上传安装包失败')
    return
  }
  releaseDraft.value.downloadUrl = response.data.url
  releaseUploadName.value = response.data.name || ''
  ElMessage.success('安装包上传成功，下载地址已填入')
}
const handleReleaseUploadError = () => {
  releaseUploading.value = false
  ElMessage.error('安装包上传失败，请检查文件大小或服务器限制')
}
const saveRelease = async (item) => { const res = await saveDuoAppRelease(item); if (res.code === 0) { ElMessage.success(item.published ? '发布版已保存' : '草稿已保存'); if (!item.ID) releaseDraft.value = emptyRelease(); load() } }
const removeRelease = async (item) => { await ElMessageBox.confirm(`删除 ${item.platform} v${item.version} 的发布记录吗？`, '删除发布版', { type: 'warning' }); const res = await deleteDuoAppRelease({ ID: item.ID }); if (res.code === 0) { ElMessage.success('已删除'); load() } }
const persistDailySetting = async () => { saving.value = true; try { const res = await saveDuoDailySetting(dailySetting.value); if (res.code === 0) { ElMessage.success('每日任务已重载'); loadRitual() } } finally { saving.value = false } }
const regenerateDaily = async () => { await ElMessageBox.confirm('仅在双方都未回答时才能更换，确认重新生成？', '重新生成', { type: 'warning' }); const res = await regenerateDuoDaily(); if (res.code === 0) { ElMessage.success('今天的问题已更新'); loadRitual() } }
const addFallback = () => fallbacks.value.push({ question: '', category: 'daily', enabled: true, useCount: 0 })
const persistFallback = async (item) => { const res = await saveDuoFallback(item); if (res.code === 0) { ElMessage.success('备用问题已保存'); loadRitual() } }
const removeFallback = async (item) => { await ElMessageBox.confirm(`删除“${item.question}”吗？`, '删除备用问题', { type: 'warning' }); const res = await deleteDuoFallback({ ID: item.ID }); if (res.code === 0) { ElMessage.success('已删除'); loadRitual() } }
const persistRecipient = async (item) => { const res = await saveDuoWechatRecipient(item); if (res.code === 0) { ElMessage.success('微信绑定已保存'); loadRitual() } }
const clearRecipient = async (item) => { await ElMessageBox.confirm('确认清除这个身份的 OpenID？', '清除绑定', { type: 'warning' }); const res = await saveDuoWechatRecipient({ ...item, openId: '', clearOpenId: true, enabled: false }); if (res.code === 0) { ElMessage.success('已清除'); loadRitual() } }
const testRecipient = async (item) => { const res = await testDuoWechatRecipient({ slot: item.slot }); if (res.code === 0) { ElMessage.success('测试消息已入队'); loadRitual() } }
const retryPush = async (item) => { const res = await retryDuoWechatPush({ ID: item.ID }); if (res.code === 0) { ElMessage.success('已重新入队'); loadRitual() } }
load()
</script>

<style scoped>
.duo-call-page{padding-top:20px}.duo-call-page :deep(.el-tabs){margin-top:18px}.duo-call-page section{margin-top:20px}.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:20px}.ritual-layout{display:grid;gap:20px}.card-header{display:flex;align-items:center;justify-content:space-between;gap:16px}.setting-grid{display:grid;gap:0 18px;grid-template-columns:repeat(auto-fit,minmax(180px,1fr))}.recipient-cards{margin-top:20px}.message-preview{width:80px;height:60px}.album-preview{width:78px;height:58px;border-radius:8px}.push-filter{width:180px}.reminder-table{margin-top:18px}.release-editor{margin-bottom:20px}.release-form{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:0 18px}.release-form .el-form-item:nth-child(3),.release-form .el-form-item:nth-child(4),.release-form .el-form-item:nth-child(5),.release-form .el-form-item:nth-child(6){grid-column:1 / -1}.release-force-switch{margin-left:18px}.release-upload-name{margin-left:12px;color:var(--el-color-success)}.release-upload-hint{display:block;margin-top:8px;color:var(--el-text-color-secondary);font-size:12px}.release-table{margin-top:20px}
</style>
