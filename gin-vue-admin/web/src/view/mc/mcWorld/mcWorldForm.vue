
<template>
  <div>
    <div class="gva-form-box">
      <el-form :model="formData" ref="elFormRef" label-position="right" :rules="rule" label-width="80px">
        <el-form-item label="世界名称:" prop="name">
    <el-input v-model="formData.name" :clearable="false" placeholder="请输入世界名称" />
</el-form-item>
        <el-form-item label="唯一标识:" prop="slug">
    <el-input v-model="formData.slug" :clearable="false" placeholder="请输入唯一标识" />
</el-form-item>
        <el-form-item label="描述:" prop="description">
    <RichEdit v-model="formData.description"/>
</el-form-item>
        <el-form-item label="MC版本:" prop="mcVersion">
    <el-input v-model="formData.mcVersion" :clearable="false" placeholder="请输入MC版本" />
</el-form-item>
        <el-form-item label="平台:" prop="platform">
    <el-input v-model="formData.platform" :clearable="false" placeholder="请输入平台" />
</el-form-item>
        <el-form-item label="路径:" prop="worldPath">
    <el-input v-model="formData.worldPath" :clearable="false" placeholder="请输入路径" />
</el-form-item>
        <el-form-item label="地图链接:" prop="mapUrl">
    <RichEdit v-model="formData.mapUrl"/>
</el-form-item>
        <el-form-item label="是否公开:" prop="isPublic">
    <el-switch v-model="formData.isPublic" active-color="#13ce66" inactive-color="#ff4949" active-text="是" inactive-text="否" clearable ></el-switch>
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
  createMcWorld,
  updateMcWorld,
  findMcWorld
} from '@/api/mc/mcWorld'

defineOptions({
    name: 'McWorldForm'
})

// 自动获取字典
import { getDictFunc } from '@/utils/format'
import { useRoute, useRouter } from "vue-router"
import { ElMessage } from 'element-plus'
import { ref, reactive } from 'vue'
// 富文本组件
import RichEdit from '@/components/richtext/rich-edit.vue'


const route = useRoute()
const router = useRouter()

// 提交按钮loading
const btnLoading = ref(false)

const type = ref('')
const formData = ref({
            name: '',
            slug: '',
            description: '',
            mcVersion: '',
            platform: '',
            worldPath: '',
            mapUrl: '',
            isPublic: false,
        })
// 验证规则
const rule = reactive({
               name : [{
                   required: true,
                   message: '',
                   trigger: ['input','blur'],
               }],
               slug : [{
                   required: true,
                   message: '',
                   trigger: ['input','blur'],
               }],
               worldPath : [{
                   required: true,
                   message: '',
                   trigger: ['input','blur'],
               }],
})

const elFormRef = ref()

// 初始化方法
const init = async () => {
 // 建议通过url传参获取目标数据ID 调用 find方法进行查询数据操作 从而决定本页面是create还是update 以下为id作为url参数示例
    if (route.query.id) {
      const res = await findMcWorld({ ID: route.query.id })
      if (res.code === 0) {
        formData.value = res.data
        type.value = 'update'
      }
    } else {
      type.value = 'create'
    }
}

init()
// 保存按钮
const save = async() => {
      btnLoading.value = true
      elFormRef.value?.validate( async (valid) => {
         if (!valid) return btnLoading.value = false
            let res
           switch (type.value) {
             case 'create':
               res = await createMcWorld(formData.value)
               break
             case 'update':
               res = await updateMcWorld(formData.value)
               break
             default:
               res = await createMcWorld(formData.value)
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
