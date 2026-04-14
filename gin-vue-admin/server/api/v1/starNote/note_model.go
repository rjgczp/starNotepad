package starNote

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/flipped-aurora/gin-vue-admin/server/global"
	"github.com/flipped-aurora/gin-vue-admin/server/model/common/request"
	"github.com/flipped-aurora/gin-vue-admin/server/model/common/response"
	"github.com/flipped-aurora/gin-vue-admin/server/model/starNote"
	starNoteReq "github.com/flipped-aurora/gin-vue-admin/server/model/starNote/request"
	systemReq "github.com/flipped-aurora/gin-vue-admin/server/model/system/request"
	"github.com/flipped-aurora/gin-vue-admin/server/utils"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
	"gorm.io/gorm"
)

type NoteModelApi struct{}

// CreateNoteModel 创建记事本
// @Tags NoteModel
// @Summary 创建记事本
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body starNote.NoteModel true "创建记事本"
// @Success 200 {object} response.Response{msg=string} "创建成功"
// @Router /evt/createNoteModel [post]
func (evtApi *NoteModelApi) CreateNoteModel(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	var evt starNote.NoteModel
	err := c.ShouldBindJSON(&evt)
	if err != nil {
		response.FailWithMessage(err.Error(), c)
		return
	}
	// 如果未传入颜色或颜色为空，则设置为淡灰色
	if evt.Color == nil || *evt.Color == "" {
		gray := "#E5E7EB"
		evt.Color = &gray
	}
	err = evtService.CreateNoteModel(ctx, &evt)
	if err != nil {
		global.GVA_LOG.Error("创建失败!", zap.Error(err))
		response.FailWithMessage("创建失败:"+err.Error(), c)
		return
	}
	response.OkWithMessage("创建成功", c)
}

// CreateUserNoteModel 用户端创建记事本
// @Tags NoteModel
// @Summary 用户端创建记事本
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body starNote.NoteModel true "创建记事本"
// @Success 200 {object} response.Response{msg=string} "创建成功"
// @Router /unote/create [post]
func (evtApi *NoteModelApi) CreateUserNoteModel(c *gin.Context) {
	ctx := c.Request.Context()
	userID := utils.GetUserID(c)

	var evt starNote.NoteModel
	if err := c.ShouldBindJSON(&evt); err != nil {
		c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"data":    gin.H{},
			"message": "参数错误",
		})
		return
	}
	// 如果未传入颜色或颜色为空，则设置为淡灰色
	if evt.Color == nil || *evt.Color == "" {
		gray := "#E5E7EB"
		evt.Color = &gray
	}
	err := evtService.CreateUserNoteModel(ctx, userID, &evt)
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
			"id": evt.ID,
		},
		"message": "创建成功",
	})
}

// DeleteNoteModel 删除记事本
// @Tags NoteModel
// @Summary 删除记事本
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body starNote.NoteModel true "删除记事本"
// @Success 200 {object} response.Response{msg=string} "删除成功"
// @Router /evt/deleteNoteModel [delete]
func (evtApi *NoteModelApi) DeleteNoteModel(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	ID := c.Query("ID")
	err := evtService.DeleteNoteModel(ctx, ID)
	if err != nil {
		global.GVA_LOG.Error("删除失败!", zap.Error(err))
		response.FailWithMessage("删除失败:"+err.Error(), c)
		return
	}
	response.OkWithMessage("删除成功", c)
}

// DeleteUserNoteModel 用户端删除记事本(仅限本人)
// @Tags NoteModel
// @Summary 用户端删除记事本
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body request.GetById true "记事本ID"
// @Success 200 {object} response.Response{msg=string} "删除成功"
// @Router /unote/delete [delete]
func (evtApi *NoteModelApi) DeleteUserNoteModel(c *gin.Context) {
	ctx := c.Request.Context()
	userID := utils.GetUserID(c)
	var req request.GetById
	err := c.ShouldBindJSON(&req)
	if err != nil {
		response.FailWithMessage(err.Error(), c)
		return
	}
	err = evtService.DeleteUserNoteModel(ctx, userID, strconv.Itoa(int(req.ID)))
	if err != nil {
		global.GVA_LOG.Error("删除失败!", zap.Error(err))
		if errors.Is(err, gorm.ErrRecordNotFound) {
			c.AbortWithStatusJSON(http.StatusNotFound, gin.H{
				"code":    http.StatusNotFound,
				"data":    gin.H{},
				"message": "记事本不存在或无权限删除",
			})
			return
		}
		c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
			"code":    http.StatusInternalServerError,
			"data":    gin.H{},
			"message": "删除失败",
		})
		return
	}
	response.OkWithMessage("删除成功", c)
}

// DeleteNoteModelByIds 批量删除记事本
// @Tags NoteModel
// @Summary 批量删除记事本
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Success 200 {object} response.Response{msg=string} "批量删除成功"
// @Router /evt/deleteNoteModelByIds [delete]
func (evtApi *NoteModelApi) DeleteNoteModelByIds(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	IDs := c.QueryArray("IDs[]")
	err := evtService.DeleteNoteModelByIds(ctx, IDs)
	if err != nil {
		global.GVA_LOG.Error("批量删除失败!", zap.Error(err))
		response.FailWithMessage("批量删除失败:"+err.Error(), c)
		return
	}
	response.OkWithMessage("批量删除成功", c)
}

// UpdateNoteModel 更新记事本
// @Tags NoteModel
// @Summary 更新记事本
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body starNote.NoteModel true "更新记事本"
// @Success 200 {object} response.Response{msg=string} "更新成功"
// @Router /evt/updateNoteModel [put]
func (evtApi *NoteModelApi) UpdateNoteModel(c *gin.Context) {
	// 从ctx获取标准context进行业务行为
	ctx := c.Request.Context()

	var evt starNote.NoteModel
	err := c.ShouldBindJSON(&evt)
	if err != nil {
		response.FailWithMessage(err.Error(), c)
		return
	}
	err = evtService.UpdateNoteModel(ctx, evt)
	if err != nil {
		global.GVA_LOG.Error("更新失败!", zap.Error(err))
		response.FailWithMessage("更新失败:"+err.Error(), c)
		return
	}
	response.OkWithMessage("更新成功", c)
}

// UpdateUserNoteModel 用户端更新记事本(仅限本人)
// @Tags UserNote
// @Summary 用户端更新记事本
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body starNote.NoteModel true "更新记事本"
// @Success 200 {object} response.Response{msg=string} "更新成功"
// @Router /unote/update [put]
func (evtApi *NoteModelApi) UpdateUserNoteModel(c *gin.Context) {
	ctx := c.Request.Context()
	userID := utils.GetUserID(c)

	var evt starNote.NoteModel
	if err := c.ShouldBindJSON(&evt); err != nil {
		c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"data":    gin.H{},
			"message": "参数错误",
		})
		return
	}
	err := evtService.UpdateUserNoteModel(ctx, userID, evt)
	if err != nil {
		global.GVA_LOG.Error("更新失败!", zap.Error(err))
		if errors.Is(err, gorm.ErrRecordNotFound) {
			c.AbortWithStatusJSON(http.StatusNotFound, gin.H{
				"code":    http.StatusNotFound,
				"data":    gin.H{},
				"message": "资源不存在",
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
	c.JSON(http.StatusOK, gin.H{
		"code":    http.StatusOK,
		"data":    gin.H{},
		"message": "更新成功",
	})
}

// FindNoteModel 用id查询记事本
// @Tags NoteModel
// @Summary 用id查询记事本
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param ID query uint true "用id查询记事本"
// @Success 200 {object} response.Response{data=starNote.NoteModel,msg=string} "查询成功"
// @Router /evt/findNoteModel [get]
func (evtApi *NoteModelApi) FindNoteModel(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	ID := c.Query("ID")
	reevt, err := evtService.GetNoteModel(ctx, ID)
	if err != nil {
		global.GVA_LOG.Error("查询失败!", zap.Error(err))
		response.FailWithMessage("查询失败:"+err.Error(), c)
		return
	}
	response.OkWithData(reevt, c)
}

// FindUserNoteModel 用户端根据ID获取记事本(仅限本人)
// @Tags NoteModel
// @Summary 用户端根据ID获取记事本
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param ID query string true "记事本ID"
// @Success 200 {object} response.Response{data=starNote.NoteModel,msg=string} "查询成功"
// @Router /unote/find [get]
func (evtApi *NoteModelApi) FindUserNoteModel(c *gin.Context) {
	ctx := c.Request.Context()
	userID := utils.GetUserID(c)
	ID := c.Query("ID")
	evt, err := evtService.GetUserNoteModel(ctx, userID, ID)
	if err != nil {
		global.GVA_LOG.Error("查询失败!", zap.Error(err))
		if errors.Is(err, gorm.ErrRecordNotFound) {
			c.AbortWithStatusJSON(http.StatusNotFound, gin.H{
				"code":    http.StatusNotFound,
				"data":    gin.H{},
				"message": "资源不存在",
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
	c.JSON(http.StatusOK, gin.H{
		"code":    http.StatusOK,
		"data":    evt,
		"message": "获取成功",
	})
}

// GetNoteModelList 分页获取记事本列表
// @Tags NoteModel
// @Summary 分页获取记事本列表
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data query starNoteReq.NoteModelSearch true "分页获取记事本列表"
// @Success 200 {object} response.Response{data=response.PageResult,msg=string} "获取成功"
// @Router /evt/getNoteModelList [get]
func (evtApi *NoteModelApi) GetNoteModelList(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	var pageInfo starNoteReq.NoteModelSearch
	err := c.ShouldBindQuery(&pageInfo)
	if err != nil {
		response.FailWithMessage(err.Error(), c)
		return
	}
	list, total, err := evtService.GetNoteModelInfoList(ctx, pageInfo)
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

// GetUserNoteModelList 用户端分页获取记事本列表(仅本人)
// @Tags NoteModel
// @Summary 用户端分页获取记事本列表
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data query starNoteReq.NoteModelSearch true "分页获取记事本列表"
// @Success 200 {object} response.Response{data=response.PageResult,msg=string} "获取成功"
// @Router /unote/list [get]
func (evtApi *NoteModelApi) GetUserNoteModelList(c *gin.Context) {
	ctx := c.Request.Context()
	userID := utils.GetUserID(c)

	var pageInfo starNoteReq.NoteModelSearch
	if err := c.ShouldBindQuery(&pageInfo); err != nil {
		c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"data":    gin.H{},
			"message": "参数错误",
		})
		return
	}
	list, total, err := evtService.GetUserNoteModelInfoList(ctx, userID, pageInfo)
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
			"list":     list,
			"total":    total,
			"page":     pageInfo.Page,
			"pageSize": pageInfo.PageSize,
		},
		"message": "获取成功",
	})
}

// GetUserNoteModelAll 用户端获取名下所有记事本(仅本人)
// @Tags UserNote
// @Summary 用户端获取名下所有记事本
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param page query int false "页码" default(1)
// @Param pageSize query int false "每页数量" default(10)
// @Param categoryId query int false "分类ID" default(0)
// @Success 200 {object} response.Response{data=object,msg=string} "获取成功"
// @Router /unote/all [get]
func (evtApi *NoteModelApi) GetUserNoteModelAll(c *gin.Context) {
	ctx := c.Request.Context()
	userID := utils.GetUserID(c)
	page := 1
	pageSize := 10
	var categoryID *int64

	if v := c.Query("page"); v != "" {
		if n, err := strconv.Atoi(v); err == nil {
			page = n
		}
	}
	if v := c.Query("pageSize"); v != "" {
		if n, err := strconv.Atoi(v); err == nil {
			pageSize = n
		}
	}
	if v := c.Query("categoryId"); v != "" {
		if n, err := strconv.ParseInt(v, 10, 64); err == nil {
			categoryID = &n
		}
	}
	if page <= 0 {
		page = 1
	}
	if pageSize < 0 {
		pageSize = 0
	}

	list, total, err := evtService.GetUserNoteModelAll(ctx, userID, page, pageSize, categoryID)
	if err != nil {
		global.GVA_LOG.Error("获取失败!", zap.Error(err))
		c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
			"code":    http.StatusInternalServerError,
			"data":    gin.H{},
			"message": "服务器内部错误",
		})
		return
	}
	if list == nil {
		list = make([]starNote.NoteModel, 0)
	}
	c.JSON(http.StatusOK, gin.H{
		"code": http.StatusOK,
		"data": gin.H{
			"list":     list,
			"total":    total,
			"page":     page,
			"pageSize": pageSize,
		},
		"message": "获取成功",
	})
}

// GetNoteModelPublic 不需要鉴权的记事本接口
// @Tags NoteModel
// @Summary 不需要鉴权的记事本接口
// @Accept application/json
// @Produce application/json
// @Success 200 {object} response.Response{data=object,msg=string} "获取成功"
// @Router /evt/getNoteModelPublic [get]
func (evtApi *NoteModelApi) GetNoteModelPublic(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	// 此接口不需要鉴权
	// 示例为返回了一个固定的消息接口，一般本接口用于C端服务，需要自己实现业务逻辑
	evtService.GetNoteModelPublic(ctx)
	response.OkWithDetailed(gin.H{
		"info": "不需要鉴权的记事本接口信息",
	}, "获取成功", c)
}

// CheckToken 检测 token 有效期（用户端）并自动续期
// @Tags NoteModel
// @Summary 检测 token 有效期并自动续期
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Success 200 {object} response.Response{data=object,msg=string} "token 有效并已续期"
// @Router /unote/checkToken [get]
func (evtApi *NoteModelApi) CheckToken(c *gin.Context) {
	userID := utils.GetUserID(c)
	claims := utils.GetUserInfo(c)

	// 生成新的 token 实现续期
	j := utils.NewJWT()
	newClaims := j.CreateClaims(systemReq.BaseClaims{
		UUID:        claims.BaseClaims.UUID,
		ID:          claims.BaseClaims.ID,
		NickName:    claims.BaseClaims.NickName,
		Username:    claims.BaseClaims.Username,
		AuthorityId: claims.BaseClaims.AuthorityId,
	})

	newToken, err := j.CreateToken(newClaims)
	if err != nil {
		global.GVA_LOG.Error("生成新token失败", zap.Error(err))
		c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
			"code":    http.StatusInternalServerError,
			"data":    gin.H{},
			"message": "token续期失败",
		})
		return
	}

	// 如果使用 Redis，也更新 Redis 中的 token
	if global.GVA_CONFIG.System.UseRedis {
		if err := utils.SetRedisJWT(newToken, claims.Username); err != nil {
			global.GVA_LOG.Error("更新Redis token失败", zap.Error(err))
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"code": http.StatusOK,
		"data": gin.H{
			"userID":  userID,
			"valid":   true,
			"token":   newToken,
			"expires": newClaims.ExpiresAt.Unix(),
		},
		"message": "token 有效并已续期",
	})
}

// GetNoteStatistics 获取用户记事本统计（按日期分组返回图标）
// @Tags UserNote
// @Summary 获取用户记事本统计
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Success 200 {object} response.Response{data=object,msg=string} "获取成功"
// @Router /unote/statistics [get]
func (evtApi *NoteModelApi) GetNoteStatistics(c *gin.Context) {
	ctx := c.Request.Context()
	userID := utils.GetUserID(c)

	dateIcons, err := evtService.GetNoteStatistics(ctx, userID)
	if err != nil {
		global.GVA_LOG.Error("获取统计失败!", zap.Error(err))
		c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
			"code":    http.StatusInternalServerError,
			"data":    gin.H{},
			"message": "服务器内部错误",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    http.StatusOK,
		"data":    dateIcons,
		"message": "获取成功",
	})
}

// GetNoteCalendar 获取用户月度记事本日历
// @Tags UserNote
// @Summary 获取用户月度记事本日历
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param date query string true "日期格式: 2026-04-01"
// @Success 200 {object} response.Response{data=object,msg=string} "获取成功"
// @Router /unote/calendar [get]
func (evtApi *NoteModelApi) GetNoteCalendar(c *gin.Context) {
	ctx := c.Request.Context()
	userID := utils.GetUserID(c)
	date := c.Query("date")

	if date == "" {
		c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"data":    gin.H{},
			"message": "日期参数不能为空",
		})
		return
	}

	notes, err := evtService.GetNoteCalendar(ctx, userID, date)
	if err != nil {
		global.GVA_LOG.Error("获取日历失败!", zap.Error(err))
		c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
			"code":    http.StatusInternalServerError,
			"data":    gin.H{},
			"message": "服务器内部错误",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    http.StatusOK,
		"data":    notes,
		"message": "获取成功",
	})
}

// PolishUserNoteText 用户端AI润色文本
// @Tags UserNote
// @Summary 用户端AI润色文本
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body starNoteReq.UserPolishReq true "待润色文本"
// @Success 200 {object} response.Response{data=object,msg=string} "获取成功"
// @Router /unote/polish [post]
func (evtApi *NoteModelApi) PolishUserNoteText(c *gin.Context) {
	ctx := c.Request.Context()

	var req starNoteReq.UserPolishReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"data":    gin.H{},
			"message": "参数错误",
		})
		return
	}
	if strings.TrimSpace(req.Text) == "" {
		c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"data":    gin.H{},
			"message": "text 不能为空",
		})
		return
	}

	result, err := aiProviderService.PolishUserInput(ctx, req.Text)
	if err != nil {
		global.GVA_LOG.Error("润色失败!", zap.Error(err))
		c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
			"code":    http.StatusInternalServerError,
			"data":    gin.H{},
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    http.StatusOK,
		"data":    result,
		"message": "获取成功",
	})
}

// SyncUserNotesPull 用户端拉取记事本增量同步数据
// @Tags UserNote
// @Summary 用户端拉取记事本增量同步数据
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body starNoteReq.UserNoteSyncPullReq false "同步参数"
// @Success 200 {object} response.Response{data=object,msg=string} "获取成功"
// @Router /unote/sync/pull [post]
func (evtApi *NoteModelApi) SyncUserNotesPull(c *gin.Context) {
	ctx := c.Request.Context()
	userID := utils.GetUserID(c)

	var req starNoteReq.UserNoteSyncPullReq
	if err := c.ShouldBindJSON(&req); err != nil && err.Error() != "EOF" {
		global.GVA_LOG.Error("SyncUserNotesPull bind error", zap.Uint("userID", userID), zap.Error(err))
		c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"data":    gin.H{},
			"message": "参数错误",
		})
		return
	}
	global.GVA_LOG.Info("SyncUserNotesPull request", zap.Uint("userID", userID), zap.Any("req", req))

	notes, categories, colors, serverSyncAt, err := evtService.SyncUserNotesPull(ctx, userID, req.LastSyncAt)
	if err != nil {
		global.GVA_LOG.Error("同步拉取失败!", zap.Error(err))
		c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
			"code":    http.StatusInternalServerError,
			"data":    gin.H{},
			"message": "服务器内部错误",
		})
		return
	}

	respNotes := make([]map[string]interface{}, 0, len(notes))
	for i := range notes {
		respNotes = append(respNotes, buildSyncItemMap(notes[i], notes[i].DeletedAt.Valid, notes[i].DeletedAt.Time))
	}

	respCategories := make([]map[string]interface{}, 0, len(categories))
	for i := range categories {
		respCategories = append(respCategories, buildSyncItemMap(categories[i], categories[i].DeletedAt.Valid, categories[i].DeletedAt.Time))
	}

	respColors := make([]map[string]interface{}, 0, len(colors))
	for i := range colors {
		respColors = append(respColors, buildSyncItemMap(colors[i], colors[i].DeletedAt.Valid, colors[i].DeletedAt.Time))
	}

	c.JSON(http.StatusOK, gin.H{
		"code": http.StatusOK,
		"data": gin.H{
			"items":        respNotes,
			"notes":        gin.H{"items": respNotes},
			"categories":   gin.H{"items": respCategories},
			"colors":       gin.H{"items": respColors},
			"serverSyncAt": serverSyncAt,
		},
		"message": "获取成功",
	})
}

// SyncUserNotesPush 用户端推送记事本增量同步数据
// @Tags UserNote
// @Summary 用户端推送记事本增量同步数据
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body starNoteReq.UserNoteSyncPushReq true "同步数据"
// @Success 200 {object} response.Response{data=object,msg=string} "同步成功"
// @Router /unote/sync/push [post]
func (evtApi *NoteModelApi) SyncUserNotesPush(c *gin.Context) {
	ctx := c.Request.Context()
	userID := utils.GetUserID(c)

	var req starNoteReq.UserNoteSyncPushReq
	if err := parseSyncPushReqWithDefaultTZ(c, &req); err != nil {
		global.GVA_LOG.Error("SyncUserNotesPush bind error", zap.Uint("userID", userID), zap.Error(err))
		c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"data":    gin.H{},
			"message": "参数错误",
		})
		return
	}
	global.GVA_LOG.Info("SyncUserNotesPush request", zap.Uint("userID", userID), zap.Any("req", req))

	serverSyncAt, err := evtService.SyncUserNotesPush(ctx, userID, req)
	if err != nil {
		global.GVA_LOG.Error("同步推送失败!", zap.Error(err))
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
			"serverSyncAt": serverSyncAt,
		},
		"message": "同步成功",
	})
}

func parseSyncPushReqWithDefaultTZ(c *gin.Context, req *starNoteReq.UserNoteSyncPushReq) error {
	body, err := io.ReadAll(c.Request.Body)
	if err != nil {
		return err
	}
	if len(strings.TrimSpace(string(body))) == 0 {
		return errors.New("EOF")
	}

	var raw map[string]interface{}
	if err = json.Unmarshal(body, &raw); err != nil {
		return err
	}

	if err = normalizeSyncPushUpserts(raw, "upserts", []string{"createdAt", "updatedAt", "recordedAt"}); err != nil {
		return err
	}
	if entityAny, ok := raw["notes"]; ok {
		entity, ok := entityAny.(map[string]interface{})
		if !ok {
			return fmt.Errorf("notes 格式错误")
		}
		if err = normalizeSyncPushUpserts(entity, "upserts", []string{"createdAt", "updatedAt", "recordedAt"}); err != nil {
			return err
		}
	}
	if entityAny, ok := raw["categories"]; ok {
		entity, ok := entityAny.(map[string]interface{})
		if !ok {
			return fmt.Errorf("categories 格式错误")
		}
		if err = normalizeSyncPushUpserts(entity, "upserts", []string{"createdAt", "updatedAt"}); err != nil {
			return err
		}
	}
	if entityAny, ok := raw["colors"]; ok {
		entity, ok := entityAny.(map[string]interface{})
		if !ok {
			return fmt.Errorf("colors 格式错误")
		}
		if err = normalizeSyncPushUpserts(entity, "upserts", []string{"createdAt", "updatedAt"}); err != nil {
			return err
		}
	}

	normalized, err := json.Marshal(raw)
	if err != nil {
		return err
	}

	return json.Unmarshal(normalized, req)
}

func normalizeSyncPushUpserts(container map[string]interface{}, upsertsKey string, timeKeys []string) error {
	upsertsAny, ok := container[upsertsKey]
	if !ok {
		return nil
	}
	upserts, ok := upsertsAny.([]interface{})
	if !ok {
		return fmt.Errorf("%s 格式错误", upsertsKey)
	}
	for i := range upserts {
		item, ok := upserts[i].(map[string]interface{})
		if !ok {
			continue
		}
		for _, timeKey := range timeKeys {
			normalizeSyncPushTimeField(item, timeKey)
		}
	}
	return nil
}

func buildSyncItemMap(v interface{}, deleted bool, deletedTime time.Time) map[string]interface{} {
	itemMap := map[string]interface{}{}
	if b, mErr := json.Marshal(v); mErr == nil {
		_ = json.Unmarshal(b, &itemMap)
	}
	if deleted {
		itemMap["deletedAt"] = deletedTime
	} else {
		itemMap["deletedAt"] = nil
	}
	return itemMap
}

func normalizeSyncPushTimeField(item map[string]interface{}, key string) {
	v, ok := item[key]
	if !ok {
		return
	}
	s, ok := v.(string)
	if !ok || strings.TrimSpace(s) == "" {
		return
	}

	if _, err := time.Parse(time.RFC3339Nano, s); err == nil {
		return
	}

	loc, _ := time.LoadLocation("Asia/Shanghai")
	layouts := []string{
		"2006-01-02T15:04:05.000",
		"2006-01-02T15:04:05",
		"2006-01-02 15:04:05.000",
		"2006-01-02 15:04:05",
	}
	for _, layout := range layouts {
		t, err := time.ParseInLocation(layout, s, loc)
		if err == nil {
			item[key] = t.Format(time.RFC3339Nano)
			return
		}
	}
}
