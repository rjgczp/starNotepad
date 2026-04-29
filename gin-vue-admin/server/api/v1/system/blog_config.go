package system

import (
	"errors"

	"github.com/flipped-aurora/gin-vue-admin/server/global"
	"github.com/flipped-aurora/gin-vue-admin/server/model/common/response"
	"github.com/flipped-aurora/gin-vue-admin/server/model/system"
	systemReq "github.com/flipped-aurora/gin-vue-admin/server/model/system/request"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
	"gorm.io/gorm"
)

type UserBlog_configApi struct{}

// CreateUserBlog_config 创建个人主页
// @Tags UserBlog_config
// @Summary 创建个人主页
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body system.UserBlog_config true "创建个人主页"
// @Success 200 {object} response.Response{msg=string} "创建成功"
// @Router /bc/createUserBlog_config [post]
func (bcApi *UserBlog_configApi) CreateUserBlog_config(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	var bc system.UserBlog_config
	err := c.ShouldBindJSON(&bc)
	if err != nil {
		response.FailWithMessage(err.Error(), c)
		return
	}
	err = bcService.CreateUserBlog_config(ctx, &bc)
	if err != nil {
		global.GVA_LOG.Error("创建失败!", zap.Error(err))
		response.FailWithMessage("创建失败:"+err.Error(), c)
		return
	}
	response.OkWithMessage("创建成功", c)
}

// DeleteUserBlog_config 删除个人主页
// @Tags UserBlog_config
// @Summary 删除个人主页
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body system.UserBlog_config true "删除个人主页"
// @Success 200 {object} response.Response{msg=string} "删除成功"
// @Router /bc/deleteUserBlog_config [delete]
func (bcApi *UserBlog_configApi) DeleteUserBlog_config(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	ID := c.Query("ID")
	err := bcService.DeleteUserBlog_config(ctx, ID)
	if err != nil {
		global.GVA_LOG.Error("删除失败!", zap.Error(err))
		response.FailWithMessage("删除失败:"+err.Error(), c)
		return
	}
	response.OkWithMessage("删除成功", c)
}

// DeleteUserBlog_configByIds 批量删除个人主页
// @Tags UserBlog_config
// @Summary 批量删除个人主页
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Success 200 {object} response.Response{msg=string} "批量删除成功"
// @Router /bc/deleteUserBlog_configByIds [delete]
func (bcApi *UserBlog_configApi) DeleteUserBlog_configByIds(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	IDs := c.QueryArray("IDs[]")
	err := bcService.DeleteUserBlog_configByIds(ctx, IDs)
	if err != nil {
		global.GVA_LOG.Error("批量删除失败!", zap.Error(err))
		response.FailWithMessage("批量删除失败:"+err.Error(), c)
		return
	}
	response.OkWithMessage("批量删除成功", c)
}

// UpdateUserBlog_config 更新个人主页
// @Tags UserBlog_config
// @Summary 更新个人主页
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body system.UserBlog_config true "更新个人主页"
// @Success 200 {object} response.Response{msg=string} "更新成功"
// @Router /bc/updateUserBlog_config [put]
func (bcApi *UserBlog_configApi) UpdateUserBlog_config(c *gin.Context) {
	// 从ctx获取标准context进行业务行为
	ctx := c.Request.Context()

	var bc system.UserBlog_config
	err := c.ShouldBindJSON(&bc)
	if err != nil {
		response.FailWithMessage(err.Error(), c)
		return
	}
	err = bcService.UpdateUserBlog_config(ctx, bc)
	if err != nil {
		global.GVA_LOG.Error("更新失败!", zap.Error(err))
		response.FailWithMessage("更新失败:"+err.Error(), c)
		return
	}
	response.OkWithMessage("更新成功", c)
}

// FindUserBlog_config 用id查询个人主页
// @Tags UserBlog_config
// @Summary 用id查询个人主页
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param ID query uint true "用id查询个人主页"
// @Success 200 {object} response.Response{data=system.UserBlog_config,msg=string} "查询成功"
// @Router /bc/findUserBlog_config [get]
func (bcApi *UserBlog_configApi) FindUserBlog_config(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	ID := c.Query("ID")
	rebc, err := bcService.GetUserBlog_config(ctx, ID)
	if err != nil {
		global.GVA_LOG.Error("查询失败!", zap.Error(err))
		response.FailWithMessage("查询失败:"+err.Error(), c)
		return
	}
	response.OkWithData(rebc, c)
}

// GetUserBlog_configList 分页获取个人主页列表
// @Tags UserBlog_config
// @Summary 分页获取个人主页列表
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data query systemReq.UserBlog_configSearch true "分页获取个人主页列表"
// @Success 200 {object} response.Response{data=response.PageResult,msg=string} "获取成功"
// @Router /bc/getUserBlog_configList [get]
func (bcApi *UserBlog_configApi) GetUserBlog_configList(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	var pageInfo systemReq.UserBlog_configSearch
	err := c.ShouldBindQuery(&pageInfo)
	if err != nil {
		response.FailWithMessage(err.Error(), c)
		return
	}
	list, total, err := bcService.GetUserBlog_configInfoList(ctx, pageInfo)
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

// GetUserBlog_configPublic 不需要鉴权的个人主页接口
// @Tags UserBlog_config
// @Summary 不需要鉴权的个人主页接口
// @Accept application/json
// @Produce application/json
// @Success 200 {object} response.Response{data=object,msg=string} "获取成功"
// @Router /bc/getUserBlog_configPublic [get]
func (bcApi *UserBlog_configApi) GetUserBlog_configPublic(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	bc, err := bcService.GetUserBlog_configPublic(ctx)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			response.OkWithDetailed(gin.H{}, "暂无个人主页配置", c)
			return
		}
		global.GVA_LOG.Error("获取个人主页配置失败", zap.Error(err))
		response.FailWithMessage("获取失败:"+err.Error(), c)
		return
	}
	response.OkWithDetailed(bc, "获取成功", c)
}
