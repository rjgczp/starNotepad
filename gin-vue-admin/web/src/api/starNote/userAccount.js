import service from '@/utils/request'
// @Tags UserAccount
// @Summary 创建用户账号
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body model.UserAccount true "创建用户账号"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"创建成功"}"
// @Router /ua/createUserAccount [post]
export const createUserAccount = (data) => {
  return service({
    url: '/ua/createUserAccount',
    method: 'post',
    data
  })
}

// @Tags UserAccount
// @Summary 删除用户账号
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body model.UserAccount true "删除用户账号"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"删除成功"}"
// @Router /ua/deleteUserAccount [delete]
export const deleteUserAccount = (params) => {
  return service({
    url: '/ua/deleteUserAccount',
    method: 'delete',
    params
  })
}

// @Tags UserAccount
// @Summary 批量删除用户账号
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body request.IdsReq true "批量删除用户账号"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"删除成功"}"
// @Router /ua/deleteUserAccount [delete]
export const deleteUserAccountByIds = (params) => {
  return service({
    url: '/ua/deleteUserAccountByIds',
    method: 'delete',
    params
  })
}

// @Tags UserAccount
// @Summary 更新用户账号
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body model.UserAccount true "更新用户账号"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"更新成功"}"
// @Router /ua/updateUserAccount [put]
export const updateUserAccount = (data) => {
  return service({
    url: '/ua/updateUserAccount',
    method: 'put',
    data
  })
}

// @Tags UserAccount
// @Summary 用id查询用户账号
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data query model.UserAccount true "用id查询用户账号"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"查询成功"}"
// @Router /ua/findUserAccount [get]
export const findUserAccount = (params) => {
  return service({
    url: '/ua/findUserAccount',
    method: 'get',
    params
  })
}

// @Tags UserAccount
// @Summary 分页获取用户账号列表
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data query request.PageInfo true "分页获取用户账号列表"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"获取成功"}"
// @Router /ua/getUserAccountList [get]
export const getUserAccountList = (params) => {
  return service({
    url: '/ua/getUserAccountList',
    method: 'get',
    params
  })
}

// @Tags UserAccount
// @Summary 不需要鉴权的用户账号接口
// @Accept application/json
// @Produce application/json
// @Param data query starNoteReq.UserAccountSearch true "分页获取用户账号列表"
// @Success 200 {object} response.Response{data=object,msg=string} "获取成功"
// @Router /ua/getUserAccountPublic [get]
export const getUserAccountPublic = () => {
  return service({
    url: '/ua/getUserAccountPublic',
    method: 'get',
  })
}

export const getAdminTags = () => {
  return service({
    url: '/admin/tags',
    method: 'get',
  })
}

export const getAdminUserTags = (userId) => {
  return service({
    url: `/admin/users/${userId}/tags`,
    method: 'get',
  })
}

export const updateAdminUserTags = (userId, data) => {
  return service({
    url: `/admin/users/${userId}/tags`,
    method: 'post',
    data,
  })
}
