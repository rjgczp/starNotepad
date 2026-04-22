package starNote

import (
	
	"github.com/flipped-aurora/gin-vue-admin/server/global"
    "github.com/flipped-aurora/gin-vue-admin/server/model/common/response"
    "github.com/flipped-aurora/gin-vue-admin/server/model/starNote"
    starNoteReq "github.com/flipped-aurora/gin-vue-admin/server/model/starNote/request"
    "github.com/gin-gonic/gin"
    "go.uber.org/zap"
)

type NoteModelApi struct {}



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
	err = evtService.CreateNoteModel(ctx,&evt)
	if err != nil {
        global.GVA_LOG.Error("创建失败!", zap.Error(err))
		response.FailWithMessage("创建失败:" + err.Error(), c)
		return
	}
    response.OkWithMessage("创建成功", c)
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
	err := evtService.DeleteNoteModel(ctx,ID)
	if err != nil {
        global.GVA_LOG.Error("删除失败!", zap.Error(err))
		response.FailWithMessage("删除失败:" + err.Error(), c)
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
	err := evtService.DeleteNoteModelByIds(ctx,IDs)
	if err != nil {
        global.GVA_LOG.Error("批量删除失败!", zap.Error(err))
		response.FailWithMessage("批量删除失败:" + err.Error(), c)
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
	err = evtService.UpdateNoteModel(ctx,evt)
	if err != nil {
        global.GVA_LOG.Error("更新失败!", zap.Error(err))
		response.FailWithMessage("更新失败:" + err.Error(), c)
		return
	}
	response.OkWithMessage("更新成功", c)
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
	reevt, err := evtService.GetNoteModel(ctx,ID)
	if err != nil {
        global.GVA_LOG.Error("查询失败!", zap.Error(err))
		response.FailWithMessage("查询失败:" + err.Error(), c)
		return
	}
	response.OkWithData(reevt, c)
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
	list, total, err := evtService.GetNoteModelInfoList(ctx,pageInfo)
	if err != nil {
	    global.GVA_LOG.Error("获取失败!", zap.Error(err))
        response.FailWithMessage("获取失败:" + err.Error(), c)
        return
    }
    response.OkWithDetailed(response.PageResult{
        List:     list,
        Total:    total,
        Page:     pageInfo.Page,
        PageSize: pageInfo.PageSize,
    }, "获取成功", c)
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
