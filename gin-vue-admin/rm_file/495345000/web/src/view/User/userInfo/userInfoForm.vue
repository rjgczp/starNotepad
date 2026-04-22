
<template>
  <div>
    <div class="gva-form-box">
      <el-form :model="formData" ref="elFormRef" label-position="right" :rules="rule" label-width="80px">
        <el-form-item label="账号/ID:" prop="username">
    <el-input v-model="formData.username" :clearable="false" placeholder="请输入账号/ID" />
</el-form-item>
        <el-form-item label="加密密码:" prop="password">
    <el-input v-model="formData.password" :clearable="false" placeholder="请输入加密密码" />
</el-form-item>
        <el-form-item label="邮箱或手机:" prop="emailPhone">
    <el-input v-model="formData.emailPhone" :clearable="false" placeholder="请输入邮箱或手机" />
</el-form-item>
        <el-form-item label="昵称:" prop="nickname">
    <el-input v-model="formData.nickname" :clearable="false" placeholder="请输入昵称" />
</el-form-item>
        <el-form-item label="头像路径:" prop="avatar">
    <el-input v-model="formData.avatar" :clearable="false" placeholder="请输入头像路径" />
</el-form-item>
        <el-form-item label="性别:" prop="gender">
    <el-input v-model.number="formData.gender" :clearable="false" placeholder="请输入性别" />
</el-form-item>
        <el-form-item label="现住址:" prop="address">
    <el-input v-model="formData.address" :clearable="false" placeholder="请输入现住址" />
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
  createUserInfo,
  updateUserInfo,
  findUserInfo
} from '@/api/User/userInfo'

defineOptions({
    name: 'UserInfoForm'
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
            username: '',
            password: '',
            emailPhone: '',
            nickname: '',
            avatar: '',
            gender: 0,
            address: '',
        })
// 验证规则
const rule = reactive({
               username : [{
                   required: true,
                   message: '',
                   trigger: ['input','blur'],
               }],
               password : [{
                   required: true,
                   message: '',
                   trigger: ['input','blur'],
               }],
               emailPhone : [{
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
      const res = await findUserInfo({ ID: route.query.id })
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
               res = await createUserInfo(formData.value)
               break
             case 'update':
               res = await updateUserInfo(formData.value)
               break
             default:
               res = await createUserInfo(formData.value)
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
