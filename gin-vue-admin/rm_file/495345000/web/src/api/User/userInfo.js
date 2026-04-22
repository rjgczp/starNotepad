import service from '@/utils/request'
// @Tags UserInfo
// @Summary 创建用户信息
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body model.UserInfo true "创建用户信息"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"创建成功"}"
// @Router /user/createUserInfo [post]
export const createUserInfo = (data) => {
  return service({
    url: '/user/createUserInfo',
    method: 'post',
    data
  })
}

// @Tags UserInfo
// @Summary 删除用户信息
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body model.UserInfo true "删除用户信息"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"删除成功"}"
// @Router /user/deleteUserInfo [delete]
export const deleteUserInfo = (params) => {
  return service({
    url: '/user/deleteUserInfo',
    method: 'delete',
    params
  })
}

// @Tags UserInfo
// @Summary 批量删除用户信息
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body request.IdsReq true "批量删除用户信息"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"删除成功"}"
// @Router /user/deleteUserInfo [delete]
export const deleteUserInfoByIds = (params) => {
  return service({
    url: '/user/deleteUserInfoByIds',
    method: 'delete',
    params
  })
}

// @Tags UserInfo
// @Summary 更新用户信息
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body model.UserInfo true "更新用户信息"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"更新成功"}"
// @Router /user/updateUserInfo [put]
export const updateUserInfo = (data) => {
  return service({
    url: '/user/updateUserInfo',
    method: 'put',
    data
  })
}

// @Tags UserInfo
// @Summary 用id查询用户信息
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data query model.UserInfo true "用id查询用户信息"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"查询成功"}"
// @Router /user/findUserInfo [get]
export const findUserInfo = (params) => {
  return service({
    url: '/user/findUserInfo',
    method: 'get',
    params
  })
}

// @Tags UserInfo
// @Summary 分页获取用户信息列表
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data query request.PageInfo true "分页获取用户信息列表"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"获取成功"}"
// @Router /user/getUserInfoList [get]
export const getUserInfoList = (params) => {
  return service({
    url: '/user/getUserInfoList',
    method: 'get',
    params
  })
}

// @Tags UserInfo
// @Summary 不需要鉴权的用户信息接口
// @Accept application/json
// @Produce application/json
// @Param data query UserReq.UserInfoSearch true "分页获取用户信息列表"
// @Success 200 {object} response.Response{data=object,msg=string} "获取成功"
// @Router /user/getUserInfoPublic [get]
export const getUserInfoPublic = () => {
  return service({
    url: '/user/getUserInfoPublic',
    method: 'get',
  })
}
