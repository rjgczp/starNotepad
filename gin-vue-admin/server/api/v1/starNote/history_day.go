package starNote

import (
	"net/http"

	"github.com/flipped-aurora/gin-vue-admin/server/global"
	"github.com/flipped-aurora/gin-vue-admin/server/model/common/response"
	"github.com/flipped-aurora/gin-vue-admin/server/model/starNote"
	starNoteReq "github.com/flipped-aurora/gin-vue-admin/server/model/starNote/request"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

type HistoryDayApi struct{}

// CreateHistoryDay 创建历史上的今天
// @Tags HistoryDay
// @Summary 创建历史上的今天
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body starNote.HistoryDay true "创建历史上的今天"
// @Success 200 {object} response.Response{msg=string} "创建成功"
// @Router /hd/createHistoryDay [post]
func (hdApi *HistoryDayApi) CreateHistoryDay(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	var hd starNote.HistoryDay
	err := c.ShouldBindJSON(&hd)
	if err != nil {
		response.FailWithMessage(err.Error(), c)
		return
	}
	err = hdService.CreateHistoryDay(ctx, &hd)
	if err != nil {
		global.GVA_LOG.Error("创建失败!", zap.Error(err))
		response.FailWithMessage("创建失败:"+err.Error(), c)
		return
	}
	response.OkWithMessage("创建成功", c)
}

// DeleteHistoryDay 删除历史上的今天
// @Tags HistoryDay
// @Summary 删除历史上的今天
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body starNote.HistoryDay true "删除历史上的今天"
// @Success 200 {object} response.Response{msg=string} "删除成功"
// @Router /hd/deleteHistoryDay [delete]
func (hdApi *HistoryDayApi) DeleteHistoryDay(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	ID := c.Query("ID")
	err := hdService.DeleteHistoryDay(ctx, ID)
	if err != nil {
		global.GVA_LOG.Error("删除失败!", zap.Error(err))
		response.FailWithMessage("删除失败:"+err.Error(), c)
		return
	}
	response.OkWithMessage("删除成功", c)
}

// DeleteHistoryDayByIds 批量删除历史上的今天
// @Tags HistoryDay
// @Summary 批量删除历史上的今天
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Success 200 {object} response.Response{msg=string} "批量删除成功"
// @Router /hd/deleteHistoryDayByIds [delete]
func (hdApi *HistoryDayApi) DeleteHistoryDayByIds(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	IDs := c.QueryArray("IDs[]")
	err := hdService.DeleteHistoryDayByIds(ctx, IDs)
	if err != nil {
		global.GVA_LOG.Error("批量删除失败!", zap.Error(err))
		response.FailWithMessage("批量删除失败:"+err.Error(), c)
		return
	}
	response.OkWithMessage("批量删除成功", c)
}

// UpdateHistoryDay 更新历史上的今天
// @Tags HistoryDay
// @Summary 更新历史上的今天
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body starNote.HistoryDay true "更新历史上的今天"
// @Success 200 {object} response.Response{msg=string} "更新成功"
// @Router /hd/updateHistoryDay [put]
func (hdApi *HistoryDayApi) UpdateHistoryDay(c *gin.Context) {
	// 从ctx获取标准context进行业务行为
	ctx := c.Request.Context()

	var hd starNote.HistoryDay
	err := c.ShouldBindJSON(&hd)
	if err != nil {
		response.FailWithMessage(err.Error(), c)
		return
	}
	err = hdService.UpdateHistoryDay(ctx, hd)
	if err != nil {
		global.GVA_LOG.Error("更新失败!", zap.Error(err))
		response.FailWithMessage("更新失败:"+err.Error(), c)
		return
	}
	response.OkWithMessage("更新成功", c)
}

// FindHistoryDay 用id查询历史上的今天
// @Tags HistoryDay
// @Summary 用id查询历史上的今天
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param ID query uint true "用id查询历史上的今天"
// @Success 200 {object} response.Response{data=starNote.HistoryDay,msg=string} "查询成功"
// @Router /hd/findHistoryDay [get]
func (hdApi *HistoryDayApi) FindHistoryDay(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	ID := c.Query("ID")
	rehd, err := hdService.GetHistoryDay(ctx, ID)
	if err != nil {
		global.GVA_LOG.Error("查询失败!", zap.Error(err))
		response.FailWithMessage("查询失败:"+err.Error(), c)
		return
	}
	response.OkWithData(rehd, c)
}

// GetHistoryDayList 分页获取历史上的今天列表
// @Tags HistoryDay
// @Summary 分页获取历史上的今天列表
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data query starNoteReq.HistoryDaySearch true "分页获取历史上的今天列表"
// @Success 200 {object} response.Response{data=response.PageResult,msg=string} "获取成功"
// @Router /hd/getHistoryDayList [get]
func (hdApi *HistoryDayApi) GetHistoryDayList(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	var pageInfo starNoteReq.HistoryDaySearch
	err := c.ShouldBindQuery(&pageInfo)
	if err != nil {
		response.FailWithMessage(err.Error(), c)
		return
	}
	list, total, err := hdService.GetHistoryDayInfoList(ctx, pageInfo)
	if err != nil {
		global.GVA_LOG.Error("获取失败!", zap.Error(err))
		response.FailWithMessage("获取失败:"+err.Error(), c)
		return
	}
	response.OkWithDetailed(response.PageResult{
		List:     list,
		Total:    total,
		Page:     pageInfo.Page,
		PageSize: pageInfo.PageSize,
	}, "获取成功", c)
}

// GetHistoryDayToday 获取今日历史上的今天（需要鉴权）
// @Tags UserHistory
// @Summary 获取今日历史上的今天（用户端）
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Success 200 {object} response.Response{data=[]starNote.HistoryDay,msg=string} "获取成功"
// @Router /hd/getHistoryDayToday [get]
func (hdApi *HistoryDayApi) GetHistoryDayToday(c *gin.Context) {
	ctx := c.Request.Context()
	list, err := hdService.GetHistoryDayToday(ctx)
	if err != nil {
		global.GVA_LOG.Error("获取失败!", zap.Error(err))
		c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
			"code":    http.StatusInternalServerError,
			"data":    gin.H{},
			"message": "服务器内部错误",
		})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"code": http.StatusOK,
		"data": gin.H{
			"list": list,
		},
		"message": "获取成功",
	})
}

// GetHistoryDayPublic 不需要鉴权的历史上的今天接口
// @Tags HistoryDay
// @Summary 不需要鉴权的历史上的今天接口
// @Accept application/json
// @Produce application/json
// @Success 200 {object} response.Response{data=object,msg=string} "获取成功"
// @Router /hd/getHistoryDayPublic [get]
func (hdApi *HistoryDayApi) GetHistoryDayPublic(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	// 此接口不需要鉴权
	// 示例为返回了一个固定的消息接口，一般本接口用于C端服务，需要自己实现业务逻辑
	hdService.GetHistoryDayPublic(ctx)
	response.OkWithDetailed(gin.H{
		"info": "不需要鉴权的历史上的今天接口信息",
	}, "获取成功", c)
}

// GetHistoryDayFuture 获取未来50天的历史上的今天数据
// @Tags HistoryDay
// @Summary 获取未来50天的历史上的今天数据
// @Accept application/json
// @Produce application/json
// @Success 200 {object} response.Response{data=object,msg=string} "获取成功"
// @Router /hd/getHistoryDayFuture [get]
func (hdApi *HistoryDayApi) GetHistoryDayFuture(c *gin.Context) {
	ctx := c.Request.Context()
	data, err := hdService.GetHistoryDayFuture(ctx)
	if err != nil {
		global.GVA_LOG.Error("获取失败!", zap.Error(err))
		c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
			"code":    http.StatusInternalServerError,
			"data":    gin.H{},
			"message": "服务器内部错误",
		})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"code":    http.StatusOK,
		"data":    data,
		"message": "获取成功",
	})
}
