
<template>
  <div>
    <div class="gva-form-box">
      <el-form :model="formData" ref="elFormRef" label-position="right" :rules="rule" label-width="80px">
        <el-form-item label="所属用户:" prop="userID">
    <el-input v-model.number="formData.userID" :clearable="false" placeholder="请输入所属用户" />
</el-form-item>
        <el-form-item label="分类:" prop="categoryID">
          <el-select v-model="formData.categoryID" filterable placeholder="请选择分类" style="width: 100%">
            <el-option
              v-for="item in categoryOptions"
              :key="item.ID"
              :label="item.name"
              :value="item.ID"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="标题:" prop="title">
    <el-input v-model="formData.title" :clearable="false" placeholder="请输入标题" />
</el-form-item>
        <el-form-item label="正文:" prop="content">
    <RichEdit v-model="formData.content"/>
</el-form-item>
        <el-form-item label="是否置顶:" prop="isTop">
    <el-switch v-model="formData.isTop" active-color="#13ce66" inactive-color="#ff4949" active-text="是" inactive-text="否" clearable ></el-switch>
</el-form-item>
        <el-form-item label="是否提醒:" prop="remind">
    <el-switch v-model="formData.remind" active-color="#13ce66" inactive-color="#ff4949" active-text="是" inactive-text="否" clearable ></el-switch>
</el-form-item>
        <el-form-item label="背景颜色:" prop="color">
          <color-picker v-model="formData.color" />
        </el-form-item>
        <el-form-item label="图标:" prop="icon">
          <icon v-model="formData.icon" />
        </el-form-item>
        <el-form-item label="文本高亮:" prop="isHighlight">
    <el-switch v-model="formData.isHighlight" active-color="#13ce66" inactive-color="#ff4949" active-text="是" inactive-text="否" clearable ></el-switch>
</el-form-item>
        <el-form-item label="记录时间:" prop="recordedAt">
    <el-date-picker v-model="formData.recordedAt" type="date" style="width:100%" placeholder="选择日期" :clearable="false" />
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
  createNoteModel,
  updateNoteModel,
  findNoteModel
} from '@/api/starNote/noteModel'
import { getNoteCategoryList } from '@/api/starNote/noteCategory'
import icon from '@/view/superAdmin/menu/icon.vue'
import ColorPicker from '@/components/colorPicker/colorPicker.vue'
// 富文本组件
import RichEdit from '@/components/richtext/rich-edit.vue'

defineOptions({
    name: 'NoteModelForm'
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
            userID: 0,
            categoryID: 0,
            title: '',
            content: '',
            isTop: false,
            remind: false,
            color: '',
            icon: '',
            isHighlight: false,
            recordedAt: new Date(),
        })
// 验证规则
const rule = reactive({
})

const elFormRef = ref()

const categoryOptions = ref([])

const setOptions = async () => {
  const res = await getNoteCategoryList({ page: 1, pageSize: 1000 })
  if (res.code === 0) {
    categoryOptions.value = res.data.list || []
  }
}

// 初始化方法
const init = async () => {
 // 建议通过url传参获取目标数据ID 调用 find方法进行查询数据操作 从而决定本页面是create还是update 以下为id作为url参数示例
    if (route.query.id) {
      const res = await findNoteModel({ ID: route.query.id })
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
               res = await createNoteModel(formData.value)
               break
             case 'update':
               res = await updateNoteModel(formData.value)
               break
             default:
               res = await createNoteModel(formData.value)
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
