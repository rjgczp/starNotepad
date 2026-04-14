import service from '@/utils/request'
// @Tags StarColor
// @Summary 创建星颜色
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body model.StarColor true "创建星颜色"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"创建成功"}"
// @Router /sc/createStarColor [post]
export const createStarColor = (data) => {
  return service({
    url: '/sc/createStarColor',
    method: 'post',
    data
  })
}

// @Tags StarColor
// @Summary 删除星颜色
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body model.StarColor true "删除星颜色"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"删除成功"}"
// @Router /sc/deleteStarColor [delete]
export const deleteStarColor = (params) => {
  return service({
    url: '/sc/deleteStarColor',
    method: 'delete',
    params
  })
}

// @Tags StarColor
// @Summary 批量删除星颜色
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body request.IdsReq true "批量删除星颜色"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"删除成功"}"
// @Router /sc/deleteStarColor [delete]
export const deleteStarColorByIds = (params) => {
  return service({
    url: '/sc/deleteStarColorByIds',
    method: 'delete',
    params
  })
}

// @Tags StarColor
// @Summary 更新星颜色
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body model.StarColor true "更新星颜色"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"更新成功"}"
// @Router /sc/updateStarColor [put]
export const updateStarColor = (data) => {
  return service({
    url: '/sc/updateStarColor',
    method: 'put',
    data
  })
}

// @Tags StarColor
// @Summary 用id查询星颜色
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data query model.StarColor true "用id查询星颜色"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"查询成功"}"
// @Router /sc/findStarColor [get]
export const findStarColor = (params) => {
  return service({
    url: '/sc/findStarColor',
    method: 'get',
    params
  })
}

// @Tags StarColor
// @Summary 分页获取星颜色列表
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data query request.PageInfo true "分页获取星颜色列表"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"获取成功"}"
// @Router /sc/getStarColorList [get]
export const getStarColorList = (params) => {
  return service({
    url: '/sc/getStarColorList',
    method: 'get',
    params
  })
}

// @Tags StarColor
// @Summary 不需要鉴权的星颜色接口
// @Accept application/json
// @Produce application/json
// @Param data query starNoteReq.StarColorSearch true "分页获取星颜色列表"
// @Success 200 {object} response.Response{data=object,msg=string} "获取成功"
// @Router /sc/getStarColorPublic [get]
export const getStarColorPublic = () => {
  return service({
    url: '/sc/getStarColorPublic',
    method: 'get',
  })
}
