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

type ProviderApi struct{}

// CreateProvider 创建AI供应商
// @Tags Provider
// @Summary 创建AI供应商
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body starNote.Provider true "创建AI供应商"
// @Success 200 {object} response.Response{msg=string} "创建成功"
// @Router /aiProvider/createProvider [post]
func (aiProviderApi *ProviderApi) CreateProvider(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	var aiProvider starNote.Provider
	err := c.ShouldBindJSON(&aiProvider)
	if err != nil {
		response.FailWithMessage(err.Error(), c)
		return
	}
	err = aiProviderService.CreateProvider(ctx, &aiProvider)
	if err != nil {
		global.GVA_LOG.Error("创建失败!", zap.Error(err))
		response.FailWithMessage("创建失败:"+err.Error(), c)
		return
	}
	response.OkWithMessage("创建成功", c)
}

// DeleteProvider 删除AI供应商
// @Tags Provider
// @Summary 删除AI供应商
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body starNote.Provider true "删除AI供应商"
// @Success 200 {object} response.Response{msg=string} "删除成功"
// @Router /aiProvider/deleteProvider [delete]
func (aiProviderApi *ProviderApi) DeleteProvider(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	ID := c.Query("ID")
	err := aiProviderService.DeleteProvider(ctx, ID)
	if err != nil {
		global.GVA_LOG.Error("删除失败!", zap.Error(err))
		response.FailWithMessage("删除失败:"+err.Error(), c)
		return
	}
	response.OkWithMessage("删除成功", c)
}

// DeleteProviderByIds 批量删除AI供应商
// @Tags Provider
// @Summary 批量删除AI供应商
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Success 200 {object} response.Response{msg=string} "批量删除成功"
// @Router /aiProvider/deleteProviderByIds [delete]
func (aiProviderApi *ProviderApi) DeleteProviderByIds(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	IDs := c.QueryArray("IDs[]")
	err := aiProviderService.DeleteProviderByIds(ctx, IDs)
	if err != nil {
		global.GVA_LOG.Error("批量删除失败!", zap.Error(err))
		response.FailWithMessage("批量删除失败:"+err.Error(), c)
		return
	}
	response.OkWithMessage("批量删除成功", c)
}

// UpdateProvider 更新AI供应商
// @Tags Provider
// @Summary 更新AI供应商
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body starNote.Provider true "更新AI供应商"
// @Success 200 {object} response.Response{msg=string} "更新成功"
// @Router /aiProvider/updateProvider [put]
func (aiProviderApi *ProviderApi) UpdateProvider(c *gin.Context) {
	// 从ctx获取标准context进行业务行为
	ctx := c.Request.Context()

	var aiProvider starNote.Provider
	err := c.ShouldBindJSON(&aiProvider)
	if err != nil {
		response.FailWithMessage(err.Error(), c)
		return
	}
	err = aiProviderService.UpdateProvider(ctx, aiProvider)
	if err != nil {
		global.GVA_LOG.Error("更新失败!", zap.Error(err))
		response.FailWithMessage("更新失败:"+err.Error(), c)
		return
	}
	response.OkWithMessage("更新成功", c)
}

// FindProvider 用id查询AI供应商
// @Tags Provider
// @Summary 用id查询AI供应商
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param ID query uint true "用id查询AI供应商"
// @Success 200 {object} response.Response{data=starNote.Provider,msg=string} "查询成功"
// @Router /aiProvider/findProvider [get]
func (aiProviderApi *ProviderApi) FindProvider(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	ID := c.Query("ID")
	reaiProvider, err := aiProviderService.GetProvider(ctx, ID)
	if err != nil {
		global.GVA_LOG.Error("查询失败!", zap.Error(err))
		response.FailWithMessage("查询失败:"+err.Error(), c)
		return
	}
	response.OkWithData(reaiProvider, c)
}

// GetProviderList 分页获取AI供应商列表
// @Tags Provider
// @Summary 分页获取AI供应商列表
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data query starNoteReq.ProviderSearch true "分页获取AI供应商列表"
// @Success 200 {object} response.Response{data=response.PageResult,msg=string} "获取成功"
// @Router /aiProvider/getProviderList [get]
func (aiProviderApi *ProviderApi) GetProviderList(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	var pageInfo starNoteReq.ProviderSearch
	err := c.ShouldBindQuery(&pageInfo)
	if err != nil {
		response.FailWithMessage(err.Error(), c)
		return
	}
	list, total, err := aiProviderService.GetProviderInfoList(ctx, pageInfo)
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

// GetProviderPublic 不需要鉴权的AI供应商接口
// @Tags Provider
// @Summary 不需要鉴权的AI供应商接口
// @Accept application/json
// @Produce application/json
// @Success 200 {object} response.Response{data=object,msg=string} "获取成功"
// @Router /aiProvider/getProviderPublic [get]
func (aiProviderApi *ProviderApi) GetProviderPublic(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	// 此接口不需要鉴权
	// 示例为返回了一个固定的消息接口，一般本接口用于C端服务，需要自己实现业务逻辑
	aiProviderService.GetProviderPublic(ctx)
	response.OkWithDetailed(gin.H{
		"info": "不需要鉴权的AI供应商接口信息",
	}, "获取成功", c)
}

// InvokeActiveProvider 调用当前启用的AI供应商
// @Tags Provider
// @Summary 调用当前启用的AI供应商
// @Accept application/json
// @Produce application/json
// @Param data body starNoteReq.ProviderInvokeReq true "通用调用参数"
// @Success 200 {object} response.Response{data=object,msg=string} "调用成功"
// @Router /aiProvider/invokeActiveProvider [post]
func (aiProviderApi *ProviderApi) InvokeActiveProvider(c *gin.Context) {
	ctx := c.Request.Context()

	var req starNoteReq.ProviderInvokeReq
	if err := c.ShouldBindJSON(&req); err != nil {
		response.FailWithMessage(err.Error(), c)
		return
	}

	data, err := aiProviderService.InvokeActiveProvider(ctx, req)
	if err != nil {
		global.GVA_LOG.Error("调用失败!", zap.Error(err))
		c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
			"code":    http.StatusInternalServerError,
			"data":    gin.H{},
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    http.StatusOK,
		"data":    data,
		"message": "调用成功",
	})
}
