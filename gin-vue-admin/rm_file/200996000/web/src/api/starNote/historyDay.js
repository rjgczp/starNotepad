import service from '@/utils/request'
// @Tags HistoryDay
// @Summary 创建历史上的今天
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body model.HistoryDay true "创建历史上的今天"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"创建成功"}"
// @Router /hd/createHistoryDay [post]
export const createHistoryDay = (data) => {
  return service({
    url: '/hd/createHistoryDay',
    method: 'post',
    data
  })
}

// @Tags HistoryDay
// @Summary 删除历史上的今天
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body model.HistoryDay true "删除历史上的今天"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"删除成功"}"
// @Router /hd/deleteHistoryDay [delete]
export const deleteHistoryDay = (params) => {
  return service({
    url: '/hd/deleteHistoryDay',
    method: 'delete',
    params
  })
}

// @Tags HistoryDay
// @Summary 批量删除历史上的今天
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body request.IdsReq true "批量删除历史上的今天"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"删除成功"}"
// @Router /hd/deleteHistoryDay [delete]
export const deleteHistoryDayByIds = (params) => {
  return service({
    url: '/hd/deleteHistoryDayByIds',
    method: 'delete',
    params
  })
}

// @Tags HistoryDay
// @Summary 更新历史上的今天
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body model.HistoryDay true "更新历史上的今天"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"更新成功"}"
// @Router /hd/updateHistoryDay [put]
export const updateHistoryDay = (data) => {
  return service({
    url: '/hd/updateHistoryDay',
    method: 'put',
    data
  })
}

// @Tags HistoryDay
// @Summary 用id查询历史上的今天
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data query model.HistoryDay true "用id查询历史上的今天"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"查询成功"}"
// @Router /hd/findHistoryDay [get]
export const findHistoryDay = (params) => {
  return service({
    url: '/hd/findHistoryDay',
    method: 'get',
    params
  })
}

// @Tags HistoryDay
// @Summary 分页获取历史上的今天列表
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data query request.PageInfo true "分页获取历史上的今天列表"
// @Success 200 {string} string "{"success":true,"data":{},"msg":"获取成功"}"
// @Router /hd/getHistoryDayList [get]
export const getHistoryDayList = (params) => {
  return service({
    url: '/hd/getHistoryDayList',
    method: 'get',
    params
  })
}

// @Tags HistoryDay
// @Summary 不需要鉴权的历史上的今天接口
// @Accept application/json
// @Produce application/json
// @Param data query starNoteReq.HistoryDaySearch true "分页获取历史上的今天列表"
// @Success 200 {object} response.Response{data=object,msg=string} "获取成功"
// @Router /hd/getHistoryDayPublic [get]
export const getHistoryDayPublic = () => {
  return service({
    url: '/hd/getHistoryDayPublic',
    method: 'get',
  })
}
