package starNote

import (
	"errors"
	"net/http"
	"strconv"

	"github.com/flipped-aurora/gin-vue-admin/server/global"
	"github.com/flipped-aurora/gin-vue-admin/server/model/common/response"
	"github.com/flipped-aurora/gin-vue-admin/server/model/starNote"
	starNoteReq "github.com/flipped-aurora/gin-vue-admin/server/model/starNote/request"
	"github.com/flipped-aurora/gin-vue-admin/server/utils"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
	"gorm.io/gorm"
)

type StarColorApi struct{}

// CreateStarColor 创建星颜色
// @Tags StarColor
// @Summary 创建星颜色
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body starNote.StarColor true "创建星颜色"
// @Success 200 {object} response.Response{msg=string} "创建成功"
// @Router /sc/createStarColor [post]
func (scApi *StarColorApi) CreateStarColor(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	var sc starNote.StarColor
	err := c.ShouldBindJSON(&sc)
	if err != nil {
		response.FailWithMessage(err.Error(), c)
		return
	}
	err = scService.CreateStarColor(ctx, &sc)
	if err != nil {
		global.GVA_LOG.Error("创建失败!", zap.Error(err))
		response.FailWithMessage("创建失败:"+err.Error(), c)
		return
	}
	response.OkWithMessage("创建成功", c)
}

// DeleteStarColor 删除星颜色
// @Tags StarColor
// @Summary 删除星颜色
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body starNote.StarColor true "删除星颜色"
// @Success 200 {object} response.Response{msg=string} "删除成功"
// @Router /sc/deleteStarColor [delete]
func (scApi *StarColorApi) DeleteStarColor(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	ID := c.Query("ID")
	err := scService.DeleteStarColor(ctx, ID)
	if err != nil {
		global.GVA_LOG.Error("删除失败!", zap.Error(err))
		response.FailWithMessage("删除失败:"+err.Error(), c)
		return
	}
	response.OkWithMessage("删除成功", c)
}

// DeleteStarColorByIds 批量删除星颜色
// @Tags StarColor
// @Summary 批量删除星颜色
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Success 200 {object} response.Response{msg=string} "批量删除成功"
// @Router /sc/deleteStarColorByIds [delete]
func (scApi *StarColorApi) DeleteStarColorByIds(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	IDs := c.QueryArray("IDs[]")
	err := scService.DeleteStarColorByIds(ctx, IDs)
	if err != nil {
		global.GVA_LOG.Error("批量删除失败!", zap.Error(err))
		response.FailWithMessage("批量删除失败:"+err.Error(), c)
		return
	}
	response.OkWithMessage("批量删除成功", c)
}

// UpdateStarColor 更新星颜色
// @Tags StarColor
// @Summary 更新星颜色
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body starNote.StarColor true "更新星颜色"
// @Success 200 {object} response.Response{msg=string} "更新成功"
// @Router /sc/updateStarColor [put]
func (scApi *StarColorApi) UpdateStarColor(c *gin.Context) {
	// 从ctx获取标准context进行业务行为
	ctx := c.Request.Context()

	var sc starNote.StarColor
	err := c.ShouldBindJSON(&sc)
	if err != nil {
		response.FailWithMessage(err.Error(), c)
		return
	}
	err = scService.UpdateStarColor(ctx, sc)
	if err != nil {
		global.GVA_LOG.Error("更新失败!", zap.Error(err))
		response.FailWithMessage("更新失败:"+err.Error(), c)
		return
	}
	response.OkWithMessage("更新成功", c)
}

// FindStarColor 用id查询星颜色
// @Tags StarColor
// @Summary 用id查询星颜色
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param ID query uint true "用id查询星颜色"
// @Success 200 {object} response.Response{data=starNote.StarColor,msg=string} "查询成功"
// @Router /sc/findStarColor [get]
func (scApi *StarColorApi) FindStarColor(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	ID := c.Query("ID")
	resc, err := scService.GetStarColor(ctx, ID)
	if err != nil {
		global.GVA_LOG.Error("查询失败!", zap.Error(err))
		response.FailWithMessage("查询失败:"+err.Error(), c)
		return
	}
	response.OkWithData(resc, c)
}

// GetStarColorList 分页获取星颜色列表
// @Tags StarColor
// @Summary 分页获取星颜色列表
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data query starNoteReq.StarColorSearch true "分页获取星颜色列表"
// @Success 200 {object} response.Response{data=response.PageResult,msg=string} "获取成功"
// @Router /sc/getStarColorList [get]
func (scApi *StarColorApi) GetStarColorList(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	var pageInfo starNoteReq.StarColorSearch
	err := c.ShouldBindQuery(&pageInfo)
	if err != nil {
		response.FailWithMessage(err.Error(), c)
		return
	}
	list, total, err := scService.GetStarColorInfoList(ctx, pageInfo)
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

// GetStarColorPublic 不需要鉴权的星颜色接口
// @Tags StarColor
// @Summary 不需要鉴权的星颜色接口
// @Accept application/json
// @Produce application/json
// @Success 200 {object} response.Response{data=object,msg=string} "获取成功"
// @Router /sc/getStarColorPublic [get]
func (scApi *StarColorApi) GetStarColorPublic(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	// 此接口不需要鉴权
	// 示例为返回了一个固定的消息接口，一般本接口用于C端服务，需要自己实现业务逻辑
	scService.GetStarColorPublic(ctx)
	response.OkWithDetailed(gin.H{
		"info": "不需要鉴权的星颜色接口信息",
	}, "获取成功", c)
}

// CreateUserStarColor 用户端添加颜色（仅本人）
// @Tags UserStarColor
// @Summary 用户端添加颜色
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body starNoteReq.UserStarColorCreateReq true "颜色信息"
// @Success 200 {object} response.Response{data=object,msg=string} "创建成功"
// @Router /uscolor/create [post]
func (scApi *StarColorApi) CreateUserStarColor(c *gin.Context) {
	ctx := c.Request.Context()
	userID := utils.GetUserID(c)

	var req starNoteReq.UserStarColorCreateReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"data":    gin.H{},
			"message": "参数错误",
		})
		return
	}

	sc, err := scService.CreateUserStarColor(ctx, userID, req.Name, req.Color)
	if err != nil {
		global.GVA_LOG.Error("创建失败!", zap.Error(err))
		c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
			"code":    http.StatusInternalServerError,
			"data":    gin.H{},
			"message": "服务器内部错误",
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"code": http.StatusCreated,
		"data": gin.H{
			"id": sc.ID,
		},
		"message": "创建成功",
	})
}

// GetUserStarColorList 用户端查询颜色（系统 + 本人）
// @Tags UserStarColor
// @Summary 用户端查询颜色（系统 + 本人）
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Success 200 {object} response.Response{data=[]starNote.StarColor,msg=string} "获取成功"
// @Router /uscolor/list [get]
func (scApi *StarColorApi) GetUserStarColorList(c *gin.Context) {
	ctx := c.Request.Context()
	userID := utils.GetUserID(c)

	list, err := scService.GetUserStarColorList(ctx, userID)
	if err != nil {
		global.GVA_LOG.Error("获取失败!", zap.Error(err))
		c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
			"code":    http.StatusInternalServerError,
			"data":    gin.H{},
			"message": "服务器内部错误",
		})
		return
	}
	response.OkWithData(list, c)
}

// UpdateUserStarColor 用户端修改颜色（仅本人）
// @Tags UserStarColor
// @Summary 用户端修改颜色
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body starNoteReq.UserStarColorUpdateReq true "颜色信息"
// @Success 200 {object} response.Response{msg=string} "更新成功"
// @Router /uscolor/update [put]
func (scApi *StarColorApi) UpdateUserStarColor(c *gin.Context) {
	ctx := c.Request.Context()
	userID := utils.GetUserID(c)

	var req starNoteReq.UserStarColorUpdateReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"data":    gin.H{},
			"message": "参数错误",
		})
		return
	}

	if err := scService.UpdateUserStarColor(ctx, userID, req.ID, req.Name, req.Color); err != nil {
		global.GVA_LOG.Error("更新失败!", zap.Error(err))
		if errors.Is(err, gorm.ErrRecordNotFound) {
			c.AbortWithStatusJSON(http.StatusNotFound, gin.H{
				"code":    http.StatusNotFound,
				"data":    gin.H{},
				"message": "颜色不存在",
			})
			return
		}
		if err.Error() == "system color not allowed" {
			c.AbortWithStatusJSON(http.StatusForbidden, gin.H{
				"code":    http.StatusForbidden,
				"data":    gin.H{},
				"message": "系统颜色不可修改",
			})
			return
		}
		c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
			"code":    http.StatusInternalServerError,
			"data":    gin.H{},
			"message": "服务器内部错误",
		})
		return
	}
	response.OkWithMessage("更新成功", c)
}

// DeleteUserStarColor 用户端删除颜色（仅本人）
// @Tags UserStarColor
// @Summary 用户端删除颜色
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param id query string true "颜色ID"
// @Success 200 {object} response.Response{msg=string} "删除成功"
// @Router /uscolor/delete [delete]
func (scApi *StarColorApi) DeleteUserStarColor(c *gin.Context) {
	ctx := c.Request.Context()
	userID := utils.GetUserID(c)
	idStr := c.Query("id")
	if idStr == "" {
		c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"data":    gin.H{},
			"message": "参数错误",
		})
		return
	}
	id64, err := strconv.ParseUint(idStr, 10, 64)
	if err != nil {
		c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"data":    gin.H{},
			"message": "参数错误",
		})
		return
	}

	if err := scService.DeleteUserStarColor(ctx, userID, uint(id64)); err != nil {
		global.GVA_LOG.Error("删除失败!", zap.Error(err))
		if errors.Is(err, gorm.ErrRecordNotFound) {
			c.AbortWithStatusJSON(http.StatusNotFound, gin.H{
				"code":    http.StatusNotFound,
				"data":    gin.H{},
				"message": "颜色不存在",
			})
			return
		}
		if err.Error() == "system color not allowed" {
			c.AbortWithStatusJSON(http.StatusForbidden, gin.H{
				"code":    http.StatusForbidden,
				"data":    gin.H{},
				"message": "系统颜色不可删除",
			})
			return
		}
		c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
			"code":    http.StatusInternalServerError,
			"data":    gin.H{},
			"message": "服务器内部错误",
		})
		return
	}
	response.OkWithMessage("删除成功", c)
}
