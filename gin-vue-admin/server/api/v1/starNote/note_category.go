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

type NoteCategoryApi struct{}

// CreateNoteCategory 创建记事本分类管理
// @Tags NoteCategory
// @Summary 创建记事本分类管理
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body starNote.NoteCategory true "创建记事本分类管理"
// @Success 200 {object} response.Response{msg=string} "创建成功"
// @Router /nc/createNoteCategory [post]
func (ncApi *NoteCategoryApi) CreateNoteCategory(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	var nc starNote.NoteCategory
	err := c.ShouldBindJSON(&nc)
	if err != nil {
		response.FailWithMessage(err.Error(), c)
		return
	}
	err = ncService.CreateNoteCategory(ctx, &nc)
	if err != nil {
		global.GVA_LOG.Error("创建失败!", zap.Error(err))
		response.FailWithMessage("创建失败:"+err.Error(), c)
		return
	}
	response.OkWithMessage("创建成功", c)
}

// DeleteNoteCategory 删除记事本分类管理
// @Tags NoteCategory
// @Summary 删除记事本分类管理
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body starNote.NoteCategory true "删除记事本分类管理"
// @Success 200 {object} response.Response{msg=string} "删除成功"
// @Router /nc/deleteNoteCategory [delete]
func (ncApi *NoteCategoryApi) DeleteNoteCategory(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	ID := c.Query("ID")
	err := ncService.DeleteNoteCategory(ctx, ID)
	if err != nil {
		global.GVA_LOG.Error("删除失败!", zap.Error(err))
		response.FailWithMessage("删除失败:"+err.Error(), c)
		return
	}
	response.OkWithMessage("删除成功", c)
}

// DeleteNoteCategoryByIds 批量删除记事本分类管理
// @Tags NoteCategory
// @Summary 批量删除记事本分类管理
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Success 200 {object} response.Response{msg=string} "批量删除成功"
// @Router /nc/deleteNoteCategoryByIds [delete]
func (ncApi *NoteCategoryApi) DeleteNoteCategoryByIds(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	IDs := c.QueryArray("IDs[]")
	err := ncService.DeleteNoteCategoryByIds(ctx, IDs)
	if err != nil {
		global.GVA_LOG.Error("批量删除失败!", zap.Error(err))
		response.FailWithMessage("批量删除失败:"+err.Error(), c)
		return
	}
	response.OkWithMessage("批量删除成功", c)
}

// UpdateNoteCategory 更新记事本分类管理
// @Tags NoteCategory
// @Summary 更新记事本分类管理
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body starNote.NoteCategory true "更新记事本分类管理"
// @Success 200 {object} response.Response{msg=string} "更新成功"
// @Router /nc/updateNoteCategory [put]
func (ncApi *NoteCategoryApi) UpdateNoteCategory(c *gin.Context) {
	// 从ctx获取标准context进行业务行为
	ctx := c.Request.Context()

	var nc starNote.NoteCategory
	err := c.ShouldBindJSON(&nc)
	if err != nil {
		response.FailWithMessage(err.Error(), c)
		return
	}
	err = ncService.UpdateNoteCategory(ctx, nc)
	if err != nil {
		global.GVA_LOG.Error("更新失败!", zap.Error(err))
		response.FailWithMessage("更新失败:"+err.Error(), c)
		return
	}
	response.OkWithMessage("更新成功", c)
}

// FindNoteCategory 用id查询记事本分类管理
// @Tags NoteCategory
// @Summary 用id查询记事本分类管理
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param ID query uint true "用id查询记事本分类管理"
// @Success 200 {object} response.Response{data=starNote.NoteCategory,msg=string} "查询成功"
// @Router /nc/findNoteCategory [get]
func (ncApi *NoteCategoryApi) FindNoteCategory(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	ID := c.Query("ID")
	renc, err := ncService.GetNoteCategory(ctx, ID)
	if err != nil {
		global.GVA_LOG.Error("查询失败!", zap.Error(err))
		response.FailWithMessage("查询失败:"+err.Error(), c)
		return
	}
	response.OkWithData(renc, c)
}

// GetNoteCategoryList 分页获取记事本分类管理列表
// @Tags NoteCategory
// @Summary 分页获取记事本分类管理列表
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data query starNoteReq.NoteCategorySearch true "分页获取记事本分类管理列表"
// @Success 200 {object} response.Response{data=response.PageResult,msg=string} "获取成功"
// @Router /nc/getNoteCategoryList [get]
func (ncApi *NoteCategoryApi) GetNoteCategoryList(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	var pageInfo starNoteReq.NoteCategorySearch
	err := c.ShouldBindQuery(&pageInfo)
	if err != nil {
		response.FailWithMessage(err.Error(), c)
		return
	}
	list, total, err := ncService.GetNoteCategoryInfoList(ctx, pageInfo)
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

// GetNoteCategoryPublic 不需要鉴权的记事本分类管理接口
// @Tags NoteCategory
// @Summary 不需要鉴权的记事本分类管理接口
// @Accept application/json
// @Produce application/json
// @Success 200 {object} response.Response{data=object,msg=string} "获取成功"
// @Router /nc/getNoteCategoryPublic [get]
func (ncApi *NoteCategoryApi) GetNoteCategoryPublic(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	// 此接口不需要鉴权
	// 示例为返回了一个固定的消息接口，一般本接口用于C端服务，需要自己实现业务逻辑
	ncService.GetNoteCategoryPublic(ctx)
	response.OkWithDetailed(gin.H{
		"info": "不需要鉴权的记事本分类管理接口信息",
	}, "获取成功", c)
}

// CreateUserNoteCategory 用户端创建分类（仅本人）
// @Tags UserNoteCategory
// @Summary 用户端创建分类
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body starNoteReq.UserNoteCategoryCreateReq true "分类信息"
// @Success 200 {object} response.Response{data=object,msg=string} "创建成功"
// @Router /uncategory/create [post]
func (ncApi *NoteCategoryApi) CreateUserNoteCategory(c *gin.Context) {
	ctx := c.Request.Context()
	userID := utils.GetUserID(c)

	var req starNoteReq.UserNoteCategoryCreateReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"data":    gin.H{},
			"message": "参数错误",
		})
		return
	}

	nc, err := ncService.CreateUserNoteCategory(ctx, userID, req.Name, req.Color, req.Icon)
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
			"id": nc.ID,
		},
		"message": "创建成功",
	})
}

// GetUserNoteCategoryList 用户端查询分类（系统 + 本人）
// @Tags UserNoteCategory
// @Summary 用户端查询分类（系统 + 本人）
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Success 200 {object} response.Response{data=[]starNote.NoteCategory,msg=string} "获取成功"
// @Router /uncategory/list [get]
func (ncApi *NoteCategoryApi) GetUserNoteCategoryList(c *gin.Context) {
	ctx := c.Request.Context()
	userID := utils.GetUserID(c)

	list, err := ncService.GetUserNoteCategoryList(ctx, userID)
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

// UpdateUserNoteCategory 用户端修改分类（仅本人）
// @Tags UserNoteCategory
// @Summary 用户端修改分类
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body starNoteReq.UserNoteCategoryUpdateReq true "分类信息"
// @Success 200 {object} response.Response{msg=string} "更新成功"
// @Router /uncategory/update [put]
func (ncApi *NoteCategoryApi) UpdateUserNoteCategory(c *gin.Context) {
	ctx := c.Request.Context()
	userID := utils.GetUserID(c)

	var req starNoteReq.UserNoteCategoryUpdateReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"data":    gin.H{},
			"message": "参数错误",
		})
		return
	}

	if err := ncService.UpdateUserNoteCategory(ctx, userID, req.ID, req.Name, req.Color, req.Icon); err != nil {
		global.GVA_LOG.Error("更新失败!", zap.Error(err))
		if errors.Is(err, gorm.ErrRecordNotFound) {
			c.AbortWithStatusJSON(http.StatusNotFound, gin.H{
				"code":    http.StatusNotFound,
				"data":    gin.H{},
				"message": "分类不存在",
			})
			return
		}
		if err.Error() == "system category not allowed" {
			c.AbortWithStatusJSON(http.StatusForbidden, gin.H{
				"code":    http.StatusForbidden,
				"data":    gin.H{},
				"message": "系统分类不可修改",
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

// DeleteUserNoteCategory 用户端删除分类（仅本人）
// @Tags UserNoteCategory
// @Summary 用户端删除分类
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param id query string true "分类ID"
// @Success 200 {object} response.Response{msg=string} "删除成功"
// @Router /uncategory/delete [delete]
func (ncApi *NoteCategoryApi) DeleteUserNoteCategory(c *gin.Context) {
	ctx := c.Request.Context()
	userID := utils.GetUserID(c)
	// 这里沿用用户端星颜色的 query 参数风格
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

	if err := ncService.DeleteUserNoteCategory(ctx, userID, uint(id64)); err != nil {
		global.GVA_LOG.Error("删除失败!", zap.Error(err))
		if errors.Is(err, gorm.ErrRecordNotFound) {
			c.AbortWithStatusJSON(http.StatusNotFound, gin.H{
				"code":    http.StatusNotFound,
				"data":    gin.H{},
				"message": "分类不存在",
			})
			return
		}
		if err.Error() == "system category not allowed" {
			c.AbortWithStatusJSON(http.StatusForbidden, gin.H{
				"code":    http.StatusForbidden,
				"data":    gin.H{},
				"message": "系统分类不可删除",
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
