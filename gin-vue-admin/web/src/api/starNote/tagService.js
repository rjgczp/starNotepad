import service from '@/utils/request'
// @Tags StarTag
// @Summary 创建用户标签
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body model.StarTag true "创建用户标签"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"创建成功"}"
// @Router /st/createStarTag [post]
export const createStarTag = (data) => {
  return service({
    url: '/st/createStarTag',
    method: 'post',
    data
  })
}

// @Tags StarTag
// @Summary 删除用户标签
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body model.StarTag true "删除用户标签"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"删除成功"}"
// @Router /st/deleteStarTag [delete]
export const deleteStarTag = (params) => {
  return service({
    url: '/st/deleteStarTag',
    method: 'delete',
    params
  })
}

// @Tags StarTag
// @Summary 批量删除用户标签
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body request.IdsReq true "批量删除用户标签"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"删除成功"}"
// @Router /st/deleteStarTag [delete]
export const deleteStarTagByIds = (params) => {
  return service({
    url: '/st/deleteStarTagByIds',
    method: 'delete',
    params
  })
}

// @Tags StarTag
// @Summary 更新用户标签
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body model.StarTag true "更新用户标签"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"更新成功"}"
// @Router /st/updateStarTag [put]
export const updateStarTag = (data) => {
  return service({
    url: '/st/updateStarTag',
    method: 'put',
    data
  })
}

// @Tags StarTag
// @Summary 用id查询用户标签
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data query model.StarTag true "用id查询用户标签"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"查询成功"}"
// @Router /st/findStarTag [get]
export const findStarTag = (params) => {
  return service({
    url: '/st/findStarTag',
    method: 'get',
    params
  })
}

// @Tags StarTag
// @Summary 分页获取用户标签列表
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data query request.PageInfo true "分页获取用户标签列表"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"获取成功"}"
// @Router /st/getStarTagList [get]
export const getStarTagList = (params) => {
  return service({
    url: '/st/getStarTagList',
    method: 'get',
    params
  })
}

// @Tags StarTag
// @Summary 不需要鉴权的用户标签接口
// @Accept application/json
// @Produce application/json
// @Param data query starNoteReq.StarTagSearch true "分页获取用户标签列表"
// @Success 200 {object} response.Response{data=object,msg=string} "获取成功"
// @Router /st/getStarTagPublic [get]
export const getStarTagPublic = () => {
  return service({
    url: '/st/getStarTagPublic',
    method: 'get',
  })
}
