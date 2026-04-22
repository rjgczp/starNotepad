
<template>
  <div>
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
        
            <el-table-column align="left" label="唯一ID" prop="id" width="120" />

            <el-table-column align="left" label="所属用户" prop="userID" width="120" />

            <el-table-column align="left" label="分类 ID" prop="categoryID" width="120" />

            <el-table-column align="left" label="标题" prop="title" width="120" />

            <el-table-column label="正文" prop="content" width="200">
   <template #default="scope">
      [富文本内容]
   </template>
</el-table-column>
            <el-table-column align="left" label="是否置顶" prop="isTop" width="120">
    <template #default="scope">{{ formatBoolean(scope.row.isTop) }}</template>
</el-table-column>
            <el-table-column align="left" label="是否提醒" prop="remind" width="120">
    <template #default="scope">{{ formatBoolean(scope.row.remind) }}</template>
</el-table-column>
            <el-table-column align="left" label="背景颜色" prop="color" width="120" />

            <el-table-column align="left" label="图标名称" prop="icon" width="120" />

            <el-table-column align="left" label="文本高亮" prop="isHighlight" width="120">
    <template #default="scope">{{ formatBoolean(scope.row.isHighlight) }}</template>
</el-table-column>
            <el-table-column align="left" label="记录时间" prop="recordedAt" width="180">
   <template #default="scope">{{ formatDate(scope.row.recordedAt) }}</template>
</el-table-column>
        <el-table-column align="left" label="操作" fixed="right" :min-width="appStore.operateMinWith">
            <template #default="scope">
            <el-button  type="primary" link class="table-button" @click="getDetails(scope.row)"><el-icon style="margin-right: 5px"><InfoFilled /></el-icon>查看</el-button>
            <el-button  type="primary" link icon="edit" class="table-button" @click="updateNoteModelFunc(scope.row)">编辑</el-button>
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
            <el-form-item label="唯一ID:" prop="id">
    <el-input v-model.number="formData.id" :clearable="false" placeholder="请输入唯一ID" />
</el-form-item>
            <el-form-item label="所属用户:" prop="userID">
    <el-input v-model.number="formData.userID" :clearable="false" placeholder="请输入所属用户" />
</el-form-item>
            <el-form-item label="分类 ID:" prop="categoryID">
    <el-input v-model.number="formData.categoryID" :clearable="false" placeholder="请输入分类 ID" />
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
    <el-input v-model="formData.color" :clearable="false" placeholder="请输入背景颜色" />
</el-form-item>
            <el-form-item label="图标名称:" prop="icon">
    <el-input v-model="formData.icon" :clearable="false" placeholder="请输入图标名称" />
</el-form-item>
            <el-form-item label="文本高亮:" prop="isHighlight">
    <el-switch v-model="formData.isHighlight" active-color="#13ce66" inactive-color="#ff4949" active-text="是" inactive-text="否" clearable ></el-switch>
</el-form-item>
            <el-form-item label="记录时间:" prop="recordedAt">
    <el-date-picker v-model="formData.recordedAt" type="date" style="width:100%" placeholder="选择日期" :clearable="false" />
</el-form-item>
          </el-form>
    </el-drawer>

    <el-drawer destroy-on-close :size="appStore.drawerSize" v-model="detailShow" :show-close="true" :before-close="closeDetailShow" title="查看">
            <el-descriptions :column="1" border>
                    <el-descriptions-item label="唯一ID">
    {{ detailForm.id }}
</el-descriptions-item>
                    <el-descriptions-item label="所属用户">
    {{ detailForm.userID }}
</el-descriptions-item>
                    <el-descriptions-item label="分类 ID">
    {{ detailForm.categoryID }}
</el-descriptions-item>
                    <el-descriptions-item label="标题">
    {{ detailForm.title }}
</el-descriptions-item>
                    <el-descriptions-item label="正文">
    <RichView v-model="detailForm.content" />
</el-descriptions-item>
                    <el-descriptions-item label="是否置顶">
    {{ detailForm.isTop }}
</el-descriptions-item>
                    <el-descriptions-item label="是否提醒">
    {{ detailForm.remind }}
</el-descriptions-item>
                    <el-descriptions-item label="背景颜色">
    {{ detailForm.color }}
</el-descriptions-item>
                    <el-descriptions-item label="图标名称">
    {{ detailForm.icon }}
</el-descriptions-item>
                    <el-descriptions-item label="文本高亮">
    {{ detailForm.isHighlight }}
</el-descriptions-item>
                    <el-descriptions-item label="记录时间">
    {{ detailForm.recordedAt }}
</el-descriptions-item>
            </el-descriptions>
        </el-drawer>

  </div>
</template>

<script setup>
import {
  createNoteModel,
  deleteNoteModel,
  deleteNoteModelByIds,
  updateNoteModel,
  findNoteModel,
  getNoteModelList
} from '@/api/starNote/noteModel'
// 富文本组件
import RichEdit from '@/components/richtext/rich-edit.vue'
import RichView from '@/components/richtext/rich-view.vue'

// 全量引入格式化工具 请按需保留
import { getDictFunc, formatDate, formatBoolean, filterDict ,filterDataSource, returnArrImg, onDownloadFile } from '@/utils/format'
import { ElMessage, ElMessageBox } from 'element-plus'
import { ref, reactive } from 'vue'
import { useAppStore } from "@/pinia"




defineOptions({
    name: 'NoteModel'
})

// 提交按钮loading
const btnLoading = ref(false)
const appStore = useAppStore()

// 控制更多查询条件显示/隐藏状态
const showAllQuery = ref(false)

// 自动化生成的字典（可能为空）以及字段
const formData = ref({
            id: 0,
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
const elSearchFormRef = ref()

// =========== 表格控制部分 ===========
const page = ref(1)
const total = ref(0)
const pageSize = ref(10)
const tableData = ref([])
const searchInfo = ref({})
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
    if (searchInfo.value.isTop === ""){
        searchInfo.value.isTop=null
    }
    if (searchInfo.value.remind === ""){
        searchInfo.value.remind=null
    }
    if (searchInfo.value.isHighlight === ""){
        searchInfo.value.isHighlight=null
    }
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
  const table = await getNoteModelList({ page: page.value, pageSize: pageSize.value, ...searchInfo.value })
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
            deleteNoteModelFunc(row)
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
      const res = await deleteNoteModelByIds({ IDs })
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
const updateNoteModelFunc = async(row) => {
    const res = await findNoteModel({ ID: row.ID })
    type.value = 'update'
    if (res.code === 0) {
        formData.value = res.data
        dialogFormVisible.value = true
    }
}


// 删除行
const deleteNoteModelFunc = async (row) => {
    const res = await deleteNoteModel({ ID: row.ID })
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
    dialogFormVisible.value = true
}

// 关闭弹窗
const closeDialog = () => {
    dialogFormVisible.value = false
    formData.value = {
        id: 0,
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
        }
}
// 弹窗确定
const enterDialog = async () => {
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
  const res = await findNoteModel({ ID: row.ID })
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

</style>
