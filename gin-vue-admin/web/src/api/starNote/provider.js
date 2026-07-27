import service from '@/utils/request'
// @Tags Provider
// @Summary 创建AI供应商
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body model.Provider true "创建AI供应商"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"创建成功"}"
// @Router /aiProvider/createProvider [post]
export const createProvider = (data) => {
  return service({
    url: '/aiProvider/createProvider',
    method: 'post',
    data
  })
}

// @Tags Provider
// @Summary 删除AI供应商
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body model.Provider true "删除AI供应商"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"删除成功"}"
// @Router /aiProvider/deleteProvider [delete]
export const deleteProvider = (params) => {
  return service({
    url: '/aiProvider/deleteProvider',
    method: 'delete',
    params
  })
}

// @Tags Provider
// @Summary 批量删除AI供应商
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body request.IdsReq true "批量删除AI供应商"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"删除成功"}"
// @Router /aiProvider/deleteProvider [delete]
export const deleteProviderByIds = (params) => {
  return service({
    url: '/aiProvider/deleteProviderByIds',
    method: 'delete',
    params
  })
}

// @Tags Provider
// @Summary 更新AI供应商
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body model.Provider true "更新AI供应商"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"更新成功"}"
// @Router /aiProvider/updateProvider [put]
export const updateProvider = (data) => {
  return service({
    url: '/aiProvider/updateProvider',
    method: 'put',
    data
  })
}

// @Tags Provider
// @Summary 用id查询AI供应商
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data query model.Provider true "用id查询AI供应商"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"查询成功"}"
// @Router /aiProvider/findProvider [get]
export const findProvider = (params) => {
  return service({
    url: '/aiProvider/findProvider',
    method: 'get',
    params
  })
}

// @Tags Provider
// @Summary 分页获取AI供应商列表
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data query request.PageInfo true "分页获取AI供应商列表"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"获取成功"}"
// @Router /aiProvider/getProviderList [get]
export const getProviderList = (params) => {
  return service({
    url: '/aiProvider/getProviderList',
    method: 'get',
    params
  })
}

// @Tags Provider
// @Summary 不需要鉴权的AI供应商接口
// @Accept application/json
// @Produce application/json
// @Param data query starNoteReq.ProviderSearch true "分页获取AI供应商列表"
// @Success 200 {object} response.Response{data=object,msg=string} "获取成功"
// @Router /aiProvider/getProviderPublic [get]
export const getProviderPublic = () => {
  return service({
    url: '/aiProvider/getProviderPublic',
    method: 'get',
  })
}
