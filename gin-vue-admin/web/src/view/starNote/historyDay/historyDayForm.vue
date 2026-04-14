
<template>
  <div>
    <div class="gva-form-box">
      <el-form :model="formData" ref="elFormRef" label-position="right" :rules="rule" label-width="80px">
        <el-form-item label="月份:" prop="month">
    <el-input v-model.number="formData.month" :clearable="false" placeholder="请输入月份" />
</el-form-item>
        <el-form-item label="日期:" prop="day">
    <el-input v-model.number="formData.day" :clearable="false" placeholder="请输入日期" />
</el-form-item>
        <el-form-item label="年份:" prop="year">
    <el-input v-model.number="formData.year" :clearable="false" placeholder="请输入年份" />
</el-form-item>
        <el-form-item label="标题:" prop="title">
    <el-input v-model="formData.title" :clearable="false" placeholder="请输入标题" />
</el-form-item>
        <el-form-item label="内容:" prop="content">
    <RichEdit v-model="formData.content"/>
</el-form-item>
        <el-form-item label="分类:" prop="type">
    <el-tree-select v-model="formData.type" placeholder="请选择分类" :data="cofcdOptions" style="width:100%" filterable :clearable="false" check-strictly></el-tree-select>
</el-form-item>
        <el-form-item label="权重:" prop="weight">
    <el-input v-model.number="formData.weight" :clearable="false" placeholder="请输入权重" />
</el-form-item>
        <el-form-item label="封面图:" prop="coverImg">
    <SelectImage
     v-model="formData.coverImg"
     file-type="image"
    />
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
  createHistoryDay,
  updateHistoryDay,
  findHistoryDay
} from '@/api/starNote/historyDay'

defineOptions({
    name: 'HistoryDayForm'
})

// 自动获取字典
import { getDictFunc } from '@/utils/format'
import { useRoute, useRouter } from "vue-router"
import { ElMessage } from 'element-plus'
import { ref, reactive } from 'vue'
// 图片选择组件
import SelectImage from '@/components/selectImage/selectImage.vue'
// 富文本组件
import RichEdit from '@/components/richtext/rich-edit.vue'


const route = useRoute()
const router = useRouter()

// 提交按钮loading
const btnLoading = ref(false)

const type = ref('')
const cofcdOptions = ref([])
const formData = ref({
            month: 0,
            day: 0,
            year: 0,
            title: '',
            content: '',
            type: '',
            weight: 0,
            coverImg: "",
        })
// 验证规则
const rule = reactive({
               month : [{
                   required: true,
                   message: '',
                   trigger: ['input','blur'],
               }],
               day : [{
                   required: true,
                   message: '',
                   trigger: ['input','blur'],
               }],
               year : [{
                   required: true,
                   message: '',
                   trigger: ['input','blur'],
               }],
               title : [{
                   required: true,
                   message: '',
                   trigger: ['input','blur'],
               }],
               type : [{
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
      const res = await findHistoryDay({ ID: route.query.id })
      if (res.code === 0) {
        formData.value = res.data
        type.value = 'update'
      }
    } else {
      type.value = 'create'
    }
    cofcdOptions.value = await getDictFunc('COFCD')
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
               res = await createHistoryDay(formData.value)
               break
             case 'update':
               res = await updateHistoryDay(formData.value)
               break
             default:
               res = await createHistoryDay(formData.value)
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
