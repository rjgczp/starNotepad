
<template>
  <div>
    <div class="gva-form-box">
      <el-form :model="formData" ref="elFormRef" label-position="right" :rules="rule" label-width="80px">
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
              <div v-for="(item, idx) in profileEditor.projects" :key="`project-${idx}`" class="mb-3 rounded border p-3">
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
        <el-form-item>
          <el-button :loading="btnLoading" type="primary" @click="save">保存</el-button>
          <el-button type="primary" @click="back">返回</el-button>
        </el-form-item>
      </el-form>
    </div>
  </div>
</template>

<script setup>
import {
  createUserBlog_config,
  updateUserBlog_config,
  findUserBlog_config
} from '@/api/system/blogConfig'

defineOptions({
    name: 'UserBlog_configForm'
})

import { useRoute, useRouter } from "vue-router"
import { ElMessage } from 'element-plus'
import { ref, reactive } from 'vue'


const route = useRoute()
const router = useRouter()

// 提交按钮loading
const btnLoading = ref(false)

const type = ref('')
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
  contact: [],
  extra: [],
})
const profileEditor = ref(createEditorState())
// 验证规则
const rule = reactive({
})

const elFormRef = ref()

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
  const baseKeys = ['siteLabel', 'name', 'title', 'bio', 'hobby', 'tags', 'projects', 'contact']
  const projects = Array.isArray(cfg.projects)
    ? cfg.projects
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

// 初始化方法
const init = async () => {
 // 建议通过url传参获取目标数据ID 调用 find方法进行查询数据操作 从而决定本页面是create还是update 以下为id作为url参数示例
    if (route.query.id) {
      const res = await findUserBlog_config({ ID: route.query.id })
      if (res.code === 0) {
        formData.value = res.data
        syncEditorFromForm()
        type.value = 'update'
      }
    } else {
      syncEditorFromForm()
      type.value = 'create'
    }
}

init()
// 保存按钮
const save = async() => {
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
           }
       })
}

// 返回按钮
const back = () => {
    router.go(-1)
}

</script>

<style>
</style>
