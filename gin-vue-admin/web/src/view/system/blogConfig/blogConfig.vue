
<template>
  <div class="blog-config-page">
    <div class="gva-search-box">
      <el-form ref="elSearchFormRef" :inline="true" :model="searchInfo" class="demo-form-inline" @keyup.enter="onSubmit">
      <el-form-item label="创建日期" prop="createdAtRange">
      <template #label>
        <span>
          创建日期
          <el-tooltip content="搜索范围是开始日期（包含）至结束日期（不包含）">
            <el-icon><QuestionFilled /></el-icon>
          </el-tooltip>
        </span>
      </template>

      <el-date-picker
            v-model="searchInfo.createdAtRange"
            class="!w-380px"
            type="datetimerange"
            range-separator="至"
            start-placeholder="开始时间"
            end-placeholder="结束时间"
          />
       </el-form-item>
      

        <template v-if="showAllQuery">
          <!-- 将需要控制显示状态的查询条件添加到此范围内 -->
        </template>

        <el-form-item>
          <el-button type="primary" icon="search" @click="onSubmit">查询</el-button>
          <el-button icon="refresh" @click="onReset">重置</el-button>
          <el-button link type="primary" icon="arrow-down" @click="showAllQuery=true" v-if="!showAllQuery">展开</el-button>
          <el-button link type="primary" icon="arrow-up" @click="showAllQuery=false" v-else>收起</el-button>
        </el-form-item>
      </el-form>
    </div>
    <div class="gva-table-box">
        <div class="gva-btn-list">
            <el-button  type="primary" icon="plus" @click="openDialog()">新增</el-button>
            <el-button  icon="delete" style="margin-left: 10px;" :disabled="!multipleSelection.length" @click="onDelete">删除</el-button>
            
        </div>
        <el-table
        ref="multipleTable"
        style="width: 100%"
        tooltip-effect="dark"
        :data="tableData"
        row-key="ID"
        @selection-change="handleSelectionChange"
        >
        <el-table-column type="selection" width="55" />
        
        <el-table-column sortable align="left" label="日期" prop="CreatedAt" width="180">
            <template #default="scope">{{ formatDate(scope.row.CreatedAt) }}</template>
        </el-table-column>
        
            <el-table-column label="个人主页数据" prop="blog_config" width="200">
    <template #default="scope">
        [JSON]
    </template>
</el-table-column>
        <el-table-column align="left" label="操作" fixed="right" :min-width="appStore.operateMinWith">
            <template #default="scope">
            <el-button  type="primary" link class="table-button" @click="getDetails(scope.row)"><el-icon style="margin-right: 5px"><InfoFilled /></el-icon>查看</el-button>
            <el-button  type="primary" link icon="edit" class="table-button" @click="updateUserBlog_configFunc(scope.row)">编辑</el-button>
            <el-button   type="primary" link icon="delete" @click="deleteRow(scope.row)">删除</el-button>
            </template>
        </el-table-column>
        </el-table>
        <div class="gva-pagination">
            <el-pagination
            layout="total, sizes, prev, pager, next, jumper"
            :current-page="page"
            :page-size="pageSize"
            :page-sizes="[10, 30, 50, 100]"
            :total="total"
            @current-change="handleCurrentChange"
            @size-change="handleSizeChange"
            />
        </div>
    </div>
    <el-drawer destroy-on-close :size="appStore.drawerSize" v-model="dialogFormVisible" :show-close="false" :before-close="closeDialog">
       <template #header>
              <div class="flex justify-between items-center">
                <span class="text-lg">{{type==='create'?'新增':'编辑'}}</span>
                <div>
                  <el-button :loading="btnLoading" type="primary" @click="enterDialog">确 定</el-button>
                  <el-button @click="closeDialog">取 消</el-button>
                </div>
              </div>
            </template>

          <el-form :model="formData" label-position="top" ref="elFormRef" :rules="rule" label-width="80px">
            <el-form-item label="个人主页数据:" prop="blog_config">
              <div class="w-full space-y-4">
                <el-input v-model="profileEditor.siteLabel" placeholder="站点标签，例如 Personal Homepage" />
                <el-input v-model="profileEditor.name" placeholder="姓名" />
                <el-input v-model="profileEditor.title" placeholder="标题" />
                <el-input v-model="profileEditor.bio" type="textarea" :rows="4" placeholder="简介" />

                <div>
                  <div class="mb-2 font-medium">兴趣词（hobby）</div>
                  <div v-for="(item, idx) in profileEditor.hobby" :key="`hobby-${idx}`" class="mb-2 flex gap-2">
                    <el-input v-model="profileEditor.hobby[idx]" placeholder="兴趣词" />
                    <el-button @click="removeRow(profileEditor.hobby, idx)">删除</el-button>
                  </div>
                  <el-button type="primary" link @click="profileEditor.hobby.push('')">添加兴趣词</el-button>
                </div>

                <div>
                  <div class="mb-2 font-medium">技能标签（tags）</div>
                  <div v-for="(item, idx) in profileEditor.tags" :key="`tag-${idx}`" class="mb-2 flex gap-2">
                    <el-input v-model="profileEditor.tags[idx]" placeholder="标签" />
                    <el-button @click="removeRow(profileEditor.tags, idx)">删除</el-button>
                  </div>
                  <el-button type="primary" link @click="profileEditor.tags.push('')">添加标签</el-button>
                </div>

                <div>
                  <div class="mb-2 font-medium">项目（projects）</div>
                  <div
                    v-for="(item, idx) in profileEditor.projects"
                    :key="`project-${idx}`"
                    class="mb-3 rounded border p-3"
                  >
                    <el-input v-model="item.name" class="mb-2" placeholder="项目名称" />
                    <el-input v-model="item.description" class="mb-2" type="textarea" :rows="2" placeholder="项目描述" />
                    <el-input v-model="item.link" placeholder="项目链接" />
                    <el-button class="mt-2" @click="removeRow(profileEditor.projects, idx)">删除项目</el-button>
                  </div>
                  <el-button
                    type="primary"
                    link
                    @click="profileEditor.projects.push({ name: '', description: '', link: '' })"
                  >
                    添加项目
                  </el-button>
                </div>

                <div>
                  <div class="mb-2 font-medium">玩过/在玩（play）</div>
                  <div
                    v-for="(item, idx) in profileEditor.play"
                    :key="`play-${idx}`"
                    class="mb-3 rounded border p-3"
                  >
                    <el-input v-model="item.name" class="mb-2" placeholder="内容名称" />
                    <el-input v-model="item.description" class="mb-2" type="textarea" :rows="2" placeholder="内容描述" />
                    <el-input v-model="item.link" placeholder="内容链接" />
                    <el-button class="mt-2" @click="removeRow(profileEditor.play, idx)">删除条目</el-button>
                  </div>
                  <el-button
                    type="primary"
                    link
                    @click="profileEditor.play.push({ name: '', description: '', link: '' })"
                  >
                    添加 play 条目
                  </el-button>
                </div>

                <div>
                  <div class="mb-2 font-medium">联系方式（contact）</div>
                  <div v-for="(item, idx) in profileEditor.contact" :key="`contact-${idx}`" class="mb-2 flex gap-2">
                    <el-input v-model="item.key" placeholder="键名（对应图标文件名）" />
                    <el-input v-model="item.value" placeholder="链接" />
                    <el-button @click="removeRow(profileEditor.contact, idx)">删除</el-button>
                  </div>
                  <el-button type="primary" link @click="profileEditor.contact.push({ key: '', value: '' })">
                    添加联系方式
                  </el-button>
                </div>

                <div>
                  <div class="mb-2 font-medium">额外字段（可选）</div>
                  <div v-for="(item, idx) in profileEditor.extra" :key="`extra-${idx}`" class="mb-2 flex gap-2">
                    <el-input v-model="item.key" placeholder="字段名" />
                    <el-input v-model="item.value" placeholder="字段值（字符串）" />
                    <el-button @click="removeRow(profileEditor.extra, idx)">删除</el-button>
                  </div>
                  <el-button type="primary" link @click="profileEditor.extra.push({ key: '', value: '' })">
                    添加额外字段
                  </el-button>
                </div>
              </div>
            </el-form-item>
          </el-form>
    </el-drawer>

    <el-drawer destroy-on-close :size="appStore.drawerSize" v-model="detailShow" :show-close="true" :before-close="closeDetailShow" title="查看">
            <el-descriptions :column="1" border>
                    <el-descriptions-item label="个人主页数据">
    <pre class="json-preview">{{ formatJson(detailForm.blog_config) }}</pre>
</el-descriptions-item>
            </el-descriptions>
        </el-drawer>

  </div>
</template>

<script setup>
import {
  createUserBlog_config,
  deleteUserBlog_config,
  deleteUserBlog_configByIds,
  updateUserBlog_config,
  findUserBlog_config,
  getUserBlog_configList
} from '@/api/system/blogConfig'

// 全量引入格式化工具 请按需保留
import { getDictFunc, formatDate, formatBoolean, filterDict ,filterDataSource, returnArrImg, onDownloadFile } from '@/utils/format'
import { ElMessage, ElMessageBox } from 'element-plus'
import { ref, reactive } from 'vue'
import { useAppStore } from "@/pinia"




defineOptions({
    name: 'UserBlog_config'
})

// 提交按钮loading
const btnLoading = ref(false)
const appStore = useAppStore()

// 控制更多查询条件显示/隐藏状态
const showAllQuery = ref(false)

// 自动化生成的字典（可能为空）以及字段
const formData = ref({
            blog_config: {},
        })
const createEditorState = () => ({
  siteLabel: '',
  name: '',
  title: '',
  bio: '',
  hobby: [],
  tags: [],
  projects: [],
  play: [],
  contact: [],
  extra: [],
})
const profileEditor = ref(createEditorState())



// 验证规则
const rule = reactive({
})

const elFormRef = ref()
const elSearchFormRef = ref()

// =========== 表格控制部分 ===========
const page = ref(1)
const total = ref(0)
const pageSize = ref(10)
const tableData = ref([])
const searchInfo = ref({})

const formatJson = (value) => {
  if (!value) return '{}'
  if (typeof value === 'string') {
    try {
      return JSON.stringify(JSON.parse(value), null, 2)
    } catch (e) {
      return value
    }
  }
  try {
    return JSON.stringify(value, null, 2)
  } catch (e) {
    return String(value)
  }
}

const removeRow = (arr, idx) => {
  arr.splice(idx, 1)
}

const toObject = (value) => {
  if (!value) return {}
  if (typeof value === 'string') {
    try {
      return JSON.parse(value)
    } catch (e) {
      return {}
    }
  }
  if (typeof value === 'object') return value
  return {}
}

const toEditorState = (value) => {
  const cfg = toObject(value)
  const baseKeys = ['siteLabel', 'name', 'title', 'bio', 'hobby', 'tags', 'projects', 'play', 'contact']
  const projects = Array.isArray(cfg.projects)
    ? cfg.projects
      .filter(item => item && typeof item === 'object')
      .map(item => ({
        name: String(item.name || ''),
        description: String(item.description || ''),
        link: String(item.link || ''),
      }))
    : []
  const play = Array.isArray(cfg.play)
    ? cfg.play
      .filter(item => item && typeof item === 'object')
      .map(item => ({
        name: String(item.name || ''),
        description: String(item.description || ''),
        link: String(item.link || ''),
      }))
    : []
  const contact = cfg.contact && typeof cfg.contact === 'object'
    ? Object.entries(cfg.contact).map(([key, val]) => ({ key, value: String(val ?? '') }))
    : []
  const extra = Object.entries(cfg)
    .filter(([key]) => !baseKeys.includes(key))
    .map(([key, val]) => ({
      key,
      value: typeof val === 'string' ? val : JSON.stringify(val),
    }))

  return {
    siteLabel: String(cfg.siteLabel || ''),
    name: String(cfg.name || ''),
    title: String(cfg.title || ''),
    bio: String(cfg.bio || ''),
    hobby: Array.isArray(cfg.hobby) ? cfg.hobby.map(v => String(v || '')) : [],
    tags: Array.isArray(cfg.tags) ? cfg.tags.map(v => String(v || '')) : [],
    projects,
    play,
    contact,
    extra,
  }
}

const syncEditorFromForm = () => {
  profileEditor.value = toEditorState(formData.value.blog_config)
}

const syncFormFromEditor = () => {
  const editor = profileEditor.value
  const next = {
    siteLabel: editor.siteLabel.trim(),
    name: editor.name.trim(),
    title: editor.title.trim(),
    bio: editor.bio.trim(),
    hobby: editor.hobby.map(v => v.trim()).filter(Boolean),
    tags: editor.tags.map(v => v.trim()).filter(Boolean),
    projects: editor.projects
      .map(item => ({
        name: String(item.name || '').trim(),
        description: String(item.description || '').trim(),
        link: String(item.link || '').trim(),
      }))
      .filter(item => item.name || item.description || item.link),
    play: editor.play
      .map(item => ({
        name: String(item.name || '').trim(),
        description: String(item.description || '').trim(),
        link: String(item.link || '').trim(),
      }))
      .filter(item => item.name || item.description || item.link),
    contact: Object.fromEntries(
      editor.contact
        .map(item => [String(item.key || '').trim(), String(item.value || '').trim()])
        .filter(([key, val]) => key && val)
    ),
  }

  editor.extra.forEach(item => {
    const key = String(item.key || '').trim()
    if (!key) return
    const raw = String(item.value || '').trim()
    if (!raw) return
    try {
      next[key] = JSON.parse(raw)
    } catch (e) {
      next[key] = raw
    }
  })

  formData.value.blog_config = next
  return true
}
// 重置
const onReset = () => {
  searchInfo.value = {}
  getTableData()
}

// 搜索
const onSubmit = () => {
  elSearchFormRef.value?.validate(async(valid) => {
    if (!valid) return
    page.value = 1
    getTableData()
  })
}

// 分页
const handleSizeChange = (val) => {
  pageSize.value = val
  getTableData()
}

// 修改页面容量
const handleCurrentChange = (val) => {
  page.value = val
  getTableData()
}

// 查询
const getTableData = async() => {
  const table = await getUserBlog_configList({ page: page.value, pageSize: pageSize.value, ...searchInfo.value })
  if (table.code === 0) {
    tableData.value = table.data.list
    total.value = table.data.total
    page.value = table.data.page
    pageSize.value = table.data.pageSize
  }
}

getTableData()

// ============== 表格控制部分结束 ===============

// 获取需要的字典 可能为空 按需保留
const setOptions = async () =>{
}

// 获取需要的字典 可能为空 按需保留
setOptions()


// 多选数据
const multipleSelection = ref([])
// 多选
const handleSelectionChange = (val) => {
    multipleSelection.value = val
}

// 删除行
const deleteRow = (row) => {
    ElMessageBox.confirm('确定要删除吗?', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
    }).then(() => {
            deleteUserBlog_configFunc(row)
        })
    }

// 多选删除
const onDelete = async() => {
  ElMessageBox.confirm('确定要删除吗?', '提示', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  }).then(async() => {
      const IDs = []
      if (multipleSelection.value.length === 0) {
        ElMessage({
          type: 'warning',
          message: '请选择要删除的数据'
        })
        return
      }
      multipleSelection.value &&
        multipleSelection.value.map(item => {
          IDs.push(item.ID)
        })
      const res = await deleteUserBlog_configByIds({ IDs })
      if (res.code === 0) {
        ElMessage({
          type: 'success',
          message: '删除成功'
        })
        if (tableData.value.length === IDs.length && page.value > 1) {
          page.value--
        }
        getTableData()
      }
      })
    }

// 行为控制标记（弹窗内部需要增还是改）
const type = ref('')

// 更新行
const updateUserBlog_configFunc = async(row) => {
    const res = await findUserBlog_config({ ID: row.ID })
    type.value = 'update'
    if (res.code === 0) {
        formData.value = res.data
        syncEditorFromForm()
        dialogFormVisible.value = true
    }
}


// 删除行
const deleteUserBlog_configFunc = async (row) => {
    const res = await deleteUserBlog_config({ ID: row.ID })
    if (res.code === 0) {
        ElMessage({
                type: 'success',
                message: '删除成功'
            })
            if (tableData.value.length === 1 && page.value > 1) {
            page.value--
        }
        getTableData()
    }
}

// 弹窗控制标记
const dialogFormVisible = ref(false)

// 打开弹窗
const openDialog = () => {
    type.value = 'create'
    formData.value = {
      blog_config: {},
    }
    syncEditorFromForm()
    dialogFormVisible.value = true
}

// 关闭弹窗
const closeDialog = () => {
    dialogFormVisible.value = false
    formData.value = {
        blog_config: {},
        }
    syncEditorFromForm()
}
// 弹窗确定
const enterDialog = async () => {
     btnLoading.value = true
     elFormRef.value?.validate( async (valid) => {
             if (!valid) return btnLoading.value = false
              if (!syncFormFromEditor()) {
                btnLoading.value = false
                return
              }
              let res
              switch (type.value) {
                case 'create':
                  res = await createUserBlog_config(formData.value)
                  break
                case 'update':
                  res = await updateUserBlog_config(formData.value)
                  break
                default:
                  res = await createUserBlog_config(formData.value)
                  break
              }
              btnLoading.value = false
              if (res.code === 0) {
                ElMessage({
                  type: 'success',
                  message: '创建/更改成功'
                })
                closeDialog()
                getTableData()
              }
      })
}

const detailForm = ref({})

// 查看详情控制标记
const detailShow = ref(false)


// 打开详情弹窗
const openDetailShow = () => {
  detailShow.value = true
}


// 打开详情
const getDetails = async (row) => {
  // 打开弹窗
  const res = await findUserBlog_config({ ID: row.ID })
  if (res.code === 0) {
    detailForm.value = res.data
    openDetailShow()
  }
}


// 关闭详情弹窗
const closeDetailShow = () => {
  detailShow.value = false
  detailForm.value = {}
}


</script>

<style>
.blog-config-page {
  padding-top: 20px;
}

.blog-config-page .gva-table-box {
  margin-top: 20px;
}

.json-preview {
  white-space: pre-wrap;
  word-break: break-word;
  margin: 0;
}

</style>
