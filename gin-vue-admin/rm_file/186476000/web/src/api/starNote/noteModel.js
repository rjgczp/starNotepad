import service from '@/utils/request'
// @Tags NoteModel
// @Summary 创建记事本
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body model.NoteModel true "创建记事本"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"创建成功"}"
// @Router /evt/createNoteModel [post]
export const createNoteModel = (data) => {
  return service({
    url: '/evt/createNoteModel',
    method: 'post',
    data
  })
}

// @Tags NoteModel
// @Summary 删除记事本
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body model.NoteModel true "删除记事本"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"删除成功"}"
// @Router /evt/deleteNoteModel [delete]
export const deleteNoteModel = (params) => {
  return service({
    url: '/evt/deleteNoteModel',
    method: 'delete',
    params
  })
}

// @Tags NoteModel
// @Summary 批量删除记事本
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body request.IdsReq true "批量删除记事本"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"删除成功"}"
// @Router /evt/deleteNoteModel [delete]
export const deleteNoteModelByIds = (params) => {
  return service({
    url: '/evt/deleteNoteModelByIds',
    method: 'delete',
    params
  })
}

// @Tags NoteModel
// @Summary 更新记事本
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body model.NoteModel true "更新记事本"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"更新成功"}"
// @Router /evt/updateNoteModel [put]
export const updateNoteModel = (data) => {
  return service({
    url: '/evt/updateNoteModel',
    method: 'put',
    data
  })
}

// @Tags NoteModel
// @Summary 用id查询记事本
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data query model.NoteModel true "用id查询记事本"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"查询成功"}"
// @Router /evt/findNoteModel [get]
export const findNoteModel = (params) => {
  return service({
    url: '/evt/findNoteModel',
    method: 'get',
    params
  })
}

// @Tags NoteModel
// @Summary 分页获取记事本列表
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data query request.PageInfo true "分页获取记事本列表"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"获取成功"}"
// @Router /evt/getNoteModelList [get]
export const getNoteModelList = (params) => {
  return service({
    url: '/evt/getNoteModelList',
    method: 'get',
    params
  })
}

// @Tags NoteModel
// @Summary 不需要鉴权的记事本接口
// @Accept application/json
// @Produce application/json
// @Param data query starNoteReq.NoteModelSearch true "分页获取记事本列表"
// @Success 200 {object} response.Response{data=object,msg=string} "获取成功"
// @Router /evt/getNoteModelPublic [get]
export const getNoteModelPublic = () => {
  return service({
    url: '/evt/getNoteModelPublic',
    method: 'get',
  })
}
