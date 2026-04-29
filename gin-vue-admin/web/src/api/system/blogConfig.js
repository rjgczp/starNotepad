import service from '@/utils/request'
// @Tags UserBlog_config
// @Summary 创建个人主页
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body model.UserBlog_config true "创建个人主页"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"创建成功"}"
// @Router /bc/createUserBlog_config [post]
export const createUserBlog_config = (data) => {
  return service({
    url: '/bc/createUserBlog_config',
    method: 'post',
    data
  })
}

// @Tags UserBlog_config
// @Summary 删除个人主页
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body model.UserBlog_config true "删除个人主页"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"删除成功"}"
// @Router /bc/deleteUserBlog_config [delete]
export const deleteUserBlog_config = (params) => {
  return service({
    url: '/bc/deleteUserBlog_config',
    method: 'delete',
    params
  })
}

// @Tags UserBlog_config
// @Summary 批量删除个人主页
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body request.IdsReq true "批量删除个人主页"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"删除成功"}"
// @Router /bc/deleteUserBlog_config [delete]
export const deleteUserBlog_configByIds = (params) => {
  return service({
    url: '/bc/deleteUserBlog_configByIds',
    method: 'delete',
    params
  })
}

// @Tags UserBlog_config
// @Summary 更新个人主页
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body model.UserBlog_config true "更新个人主页"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"更新成功"}"
// @Router /bc/updateUserBlog_config [put]
export const updateUserBlog_config = (data) => {
  return service({
    url: '/bc/updateUserBlog_config',
    method: 'put',
    data
  })
}

// @Tags UserBlog_config
// @Summary 用id查询个人主页
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data query model.UserBlog_config true "用id查询个人主页"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"查询成功"}"
// @Router /bc/findUserBlog_config [get]
export const findUserBlog_config = (params) => {
  return service({
    url: '/bc/findUserBlog_config',
    method: 'get',
    params
  })
}

// @Tags UserBlog_config
// @Summary 分页获取个人主页列表
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data query request.PageInfo true "分页获取个人主页列表"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"获取成功"}"
// @Router /bc/getUserBlog_configList [get]
export const getUserBlog_configList = (params) => {
  return service({
    url: '/bc/getUserBlog_configList',
    method: 'get',
    params
  })
}

// @Tags UserBlog_config
// @Summary 不需要鉴权的个人主页接口
// @Accept application/json
// @Produce application/json
// @Param data query systemReq.UserBlog_configSearch true "分页获取个人主页列表"
// @Success 200 {object} response.Response{data=object,msg=string} "获取成功"
// @Router /bc/getUserBlog_configPublic [get]
export const getUserBlog_configPublic = () => {
  return service({
    url: '/bc/getUserBlog_configPublic',
    method: 'get',
  })
}
