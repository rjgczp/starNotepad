
<template>
  <div>
    <div class="gva-form-box">
      <el-form :model="formData" ref="elFormRef" label-position="right" :rules="rule" label-width="80px">
        <el-form-item label="提供商名称:" prop="providerName">
    <el-input v-model="formData.providerName" :clearable="false" placeholder="请输入提供商名称" />
</el-form-item>
        <el-form-item label="API地址:" prop="baseUrl">
    <el-input v-model="formData.baseUrl" :clearable="false" placeholder="请输入API地址" />
</el-form-item>
        <el-form-item label="密钥:" prop="apiKey">
    <el-input v-model="formData.apiKey" :clearable="false" placeholder="请输入密钥" />
</el-form-item>
        <el-form-item label="是否启用:" prop="isActive">
    <el-switch v-model="formData.isActive" active-color="#13ce66" inactive-color="#ff4949" active-text="是" inactive-text="否" clearable ></el-switch>
</el-form-item>
        <el-form-item label="配置参数:" prop="configJson">
    <el-input v-model="formData.configJson" :clearable="false" placeholder="请输入配置参数" />
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
  createProvider,
  updateProvider,
  findProvider
} from '@/api/starNote/provider'

defineOptions({
    name: 'ProviderForm'
})

// 自动获取字典
import { getDictFunc } from '@/utils/format'
import { useRoute, useRouter } from "vue-router"
import { ElMessage } from 'element-plus'
import { ref, reactive } from 'vue'


const route = useRoute()
const router = useRouter()

// 提交按钮loading
const btnLoading = ref(false)

const type = ref('')
const formData = ref({
            providerName: '',
            baseUrl: '',
            apiKey: '',
            isActive: false,
            configJson: '',
        })
// 验证规则
const rule = reactive({
               providerName : [{
                   required: true,
                   message: '',
                   trigger: ['input','blur'],
               }],
               baseUrl : [{
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
      const res = await findProvider({ ID: route.query.id })
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
               res = await createProvider(formData.value)
               break
             case 'update':
               res = await updateProvider(formData.value)
               break
             default:
               res = await createProvider(formData.value)
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
