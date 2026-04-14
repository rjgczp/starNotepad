import service from '@/utils/request'
// @Tags NoteCategory
// @Summary 创建记事本分类管理
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body model.NoteCategory true "创建记事本分类管理"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"创建成功"}"
// @Router /nc/createNoteCategory [post]
export const createNoteCategory = (data) => {
  return service({
    url: '/nc/createNoteCategory',
    method: 'post',
    data
  })
}

// @Tags NoteCategory
// @Summary 删除记事本分类管理
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body model.NoteCategory true "删除记事本分类管理"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"删除成功"}"
// @Router /nc/deleteNoteCategory [delete]
export const deleteNoteCategory = (params) => {
  return service({
    url: '/nc/deleteNoteCategory',
    method: 'delete',
    params
  })
}

// @Tags NoteCategory
// @Summary 批量删除记事本分类管理
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body request.IdsReq true "批量删除记事本分类管理"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"删除成功"}"
// @Router /nc/deleteNoteCategory [delete]
export const deleteNoteCategoryByIds = (params) => {
  return service({
    url: '/nc/deleteNoteCategoryByIds',
    method: 'delete',
    params
  })
}

// @Tags NoteCategory
// @Summary 更新记事本分类管理
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body model.NoteCategory true "更新记事本分类管理"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"更新成功"}"
// @Router /nc/updateNoteCategory [put]
export const updateNoteCategory = (data) => {
  return service({
    url: '/nc/updateNoteCategory',
    method: 'put',
    data
  })
}

// @Tags NoteCategory
// @Summary 用id查询记事本分类管理
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data query model.NoteCategory true "用id查询记事本分类管理"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"查询成功"}"
// @Router /nc/findNoteCategory [get]
export const findNoteCategory = (params) => {
  return service({
    url: '/nc/findNoteCategory',
    method: 'get',
    params
  })
}

// @Tags NoteCategory
// @Summary 分页获取记事本分类管理列表
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data query request.PageInfo true "分页获取记事本分类管理列表"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"获取成功"}"
// @Router /nc/getNoteCategoryList [get]
export const getNoteCategoryList = (params) => {
  return service({
    url: '/nc/getNoteCategoryList',
    method: 'get',
    params
  })
}

// @Tags NoteCategory
// @Summary 不需要鉴权的记事本分类管理接口
// @Accept application/json
// @Produce application/json
// @Param data query starNoteReq.NoteCategorySearch true "分页获取记事本分类管理列表"
// @Success 200 {object} response.Response{data=object,msg=string} "获取成功"
// @Router /nc/getNoteCategoryPublic [get]
export const getNoteCategoryPublic = () => {
  return service({
    url: '/nc/getNoteCategoryPublic',
    method: 'get',
  })
}
