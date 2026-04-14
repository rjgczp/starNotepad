
<template>
  <div>
    <div class="gva-form-box">
      <el-form :model="formData" ref="elFormRef" label-position="right" :rules="rule" label-width="80px">
        <el-form-item label="名称:" prop="name">
    <el-input v-model="formData.name" :clearable="false" placeholder="请输入名称" />
</el-form-item>
        <el-form-item label="颜色:" prop="color">
          <el-select v-model="formData.color" filterable placeholder="请选择颜色" style="width: 100%">
            <el-option
              v-for="item in starColorOptions"
              :key="item.ID"
              :label="item.colors"
              :value="item.color"
            />
          </el-select>
</el-form-item>
        <el-form-item label="图标:" prop="icon">
          <icon v-model="formData.icon" />
</el-form-item>
        <el-form-item label="用户ID:" prop="userID">
    <el-input v-model.number="formData.userID" :clearable="true" placeholder="请输入用户ID" />
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
  createNoteCategory,
  updateNoteCategory,
  findNoteCategory
} from '@/api/starNote/noteCategory'
import { getStarColorList } from '@/api/starNote/starColor'
import icon from '@/view/superAdmin/menu/icon.vue'

defineOptions({
    name: 'NoteCategoryForm'
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
            name: '',
            color: '',
            icon: '',
            userID: undefined,
        })
// 验证规则
const rule = reactive({
               name : [{
                   required: true,
                   message: '',
                   trigger: ['input','blur'],
               }],
})

const elFormRef = ref()

const starColorOptions = ref([])

const setOptions = async () => {
  const res = await getStarColorList({ page: 1, pageSize: 1000 })
  if (res.code === 0) {
    starColorOptions.value = res.data.list || []
  }
}

// 初始化方法
const init = async () => {
 // 建议通过url传参获取目标数据ID 调用 find方法进行查询数据操作 从而决定本页面是create还是update 以下为id作为url参数示例
    if (route.query.id) {
      const res = await findNoteCategory({ ID: route.query.id })
      if (res.code === 0) {
        formData.value = res.data
        type.value = 'update'
      }
    } else {
      type.value = 'create'
    }
}

init()

setOptions()
// 保存按钮
const save = async() => {
      btnLoading.value = true
      elFormRef.value?.validate( async (valid) => {
         if (!valid) return btnLoading.value = false
            let res
           switch (type.value) {
             case 'create':
               res = await createNoteCategory(formData.value)
               break
             case 'update':
               res = await updateNoteCategory(formData.value)
               break
             default:
               res = await createNoteCategory(formData.value)
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
