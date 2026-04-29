import service from '@/utils/request'
// @Tags McWorld
// @Summary 创建MC世界
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body model.McWorld true "创建MC世界"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"创建成功"}"
// @Router /mcworld/createMcWorld [post]
export const createMcWorld = (data) => {
  return service({
    url: '/mcworld/createMcWorld',
    method: 'post',
    data
  })
}

// @Tags McWorld
// @Summary 删除MC世界
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body model.McWorld true "删除MC世界"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"删除成功"}"
// @Router /mcworld/deleteMcWorld [delete]
export const deleteMcWorld = (params) => {
  return service({
    url: '/mcworld/deleteMcWorld',
    method: 'delete',
    params
  })
}

// @Tags McWorld
// @Summary 批量删除MC世界
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body request.IdsReq true "批量删除MC世界"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"删除成功"}"
// @Router /mcworld/deleteMcWorld [delete]
export const deleteMcWorldByIds = (params) => {
  return service({
    url: '/mcworld/deleteMcWorldByIds',
    method: 'delete',
    params
  })
}

// @Tags McWorld
// @Summary 更新MC世界
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body model.McWorld true "更新MC世界"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"更新成功"}"
// @Router /mcworld/updateMcWorld [put]
export const updateMcWorld = (data) => {
  return service({
    url: '/mcworld/updateMcWorld',
    method: 'put',
    data
  })
}

// @Tags McWorld
// @Summary 用id查询MC世界
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data query model.McWorld true "用id查询MC世界"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"查询成功"}"
// @Router /mcworld/findMcWorld [get]
export const findMcWorld = (params) => {
  return service({
    url: '/mcworld/findMcWorld',
    method: 'get',
    params
  })
}

// @Tags McWorld
// @Summary 分页获取MC世界列表
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data query request.PageInfo true "分页获取MC世界列表"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"获取成功"}"
// @Router /mcworld/getMcWorldList [get]
export const getMcWorldList = (params) => {
  return service({
    url: '/mcworld/getMcWorldList',
    method: 'get',
    params
  })
}

// @Tags McWorld
// @Summary 不需要鉴权的MC世界接口
// @Accept application/json
// @Produce application/json
// @Param data query mcReq.McWorldSearch true "分页获取MC世界列表"
// @Success 200 {object} response.Response{data=object,msg=string} "获取成功"
// @Router /mcworld/getMcWorldPublic [get]
export const getMcWorldPublic = () => {
  return service({
    url: '/mcworld/getMcWorldPublic',
    method: 'get',
  })
}
