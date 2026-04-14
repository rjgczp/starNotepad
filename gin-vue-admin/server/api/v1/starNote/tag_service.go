package starNote

import (
	
	"github.com/flipped-aurora/gin-vue-admin/server/global"
    "github.com/flipped-aurora/gin-vue-admin/server/model/common/response"
    "github.com/flipped-aurora/gin-vue-admin/server/model/starNote"
    starNoteReq "github.com/flipped-aurora/gin-vue-admin/server/model/starNote/request"
    "github.com/gin-gonic/gin"
    "go.uber.org/zap"
)

type StarTagApi struct {}



// CreateStarTag 创建用户标签
// @Tags StarTag
// @Summary 创建用户标签
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body starNote.StarTag true "创建用户标签"
// @Success 200 {object} response.Response{msg=string} "创建成功"
// @Router /st/createStarTag [post]
func (stApi *StarTagApi) CreateStarTag(c *gin.Context) {
    // 创建业务用Context
    ctx := c.Request.Context()

	var st starNote.StarTag
	err := c.ShouldBindJSON(&st)
	if err != nil {
		response.FailWithMessage(err.Error(), c)
		return
	}
	err = stService.CreateStarTag(ctx,&st)
	if err != nil {
        global.GVA_LOG.Error("创建失败!", zap.Error(err))
		response.FailWithMessage("创建失败:" + err.Error(), c)
		return
	}
    response.OkWithMessage("创建成功", c)
}

// DeleteStarTag 删除用户标签
// @Tags StarTag
// @Summary 删除用户标签
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body starNote.StarTag true "删除用户标签"
// @Success 200 {object} response.Response{msg=string} "删除成功"
// @Router /st/deleteStarTag [delete]
func (stApi *StarTagApi) DeleteStarTag(c *gin.Context) {
    // 创建业务用Context
    ctx := c.Request.Context()

	ID := c.Query("ID")
	err := stService.DeleteStarTag(ctx,ID)
	if err != nil {
        global.GVA_LOG.Error("删除失败!", zap.Error(err))
		response.FailWithMessage("删除失败:" + err.Error(), c)
		return
	}
	response.OkWithMessage("删除成功", c)
}

// DeleteStarTagByIds 批量删除用户标签
// @Tags StarTag
// @Summary 批量删除用户标签
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Success 200 {object} response.Response{msg=string} "批量删除成功"
// @Router /st/deleteStarTagByIds [delete]
func (stApi *StarTagApi) DeleteStarTagByIds(c *gin.Context) {
    // 创建业务用Context
    ctx := c.Request.Context()

	IDs := c.QueryArray("IDs[]")
	err := stService.DeleteStarTagByIds(ctx,IDs)
	if err != nil {
        global.GVA_LOG.Error("批量删除失败!", zap.Error(err))
		response.FailWithMessage("批量删除失败:" + err.Error(), c)
		return
	}
	response.OkWithMessage("批量删除成功", c)
}

// UpdateStarTag 更新用户标签
// @Tags StarTag
// @Summary 更新用户标签
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body starNote.StarTag true "更新用户标签"
// @Success 200 {object} response.Response{msg=string} "更新成功"
// @Router /st/updateStarTag [put]
func (stApi *StarTagApi) UpdateStarTag(c *gin.Context) {
    // 从ctx获取标准context进行业务行为
    ctx := c.Request.Context()

	var st starNote.StarTag
	err := c.ShouldBindJSON(&st)
	if err != nil {
		response.FailWithMessage(err.Error(), c)
		return
	}
	err = stService.UpdateStarTag(ctx,st)
	if err != nil {
        global.GVA_LOG.Error("更新失败!", zap.Error(err))
		response.FailWithMessage("更新失败:" + err.Error(), c)
		return
	}
	response.OkWithMessage("更新成功", c)
}

// FindStarTag 用id查询用户标签
// @Tags StarTag
// @Summary 用id查询用户标签
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param ID query uint true "用id查询用户标签"
// @Success 200 {object} response.Response{data=starNote.StarTag,msg=string} "查询成功"
// @Router /st/findStarTag [get]
func (stApi *StarTagApi) FindStarTag(c *gin.Context) {
    // 创建业务用Context
    ctx := c.Request.Context()

	ID := c.Query("ID")
	rest, err := stService.GetStarTag(ctx,ID)
	if err != nil {
        global.GVA_LOG.Error("查询失败!", zap.Error(err))
		response.FailWithMessage("查询失败:" + err.Error(), c)
		return
	}
	response.OkWithData(rest, c)
}
// GetStarTagList 分页获取用户标签列表
// @Tags StarTag
// @Summary 分页获取用户标签列表
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data query starNoteReq.StarTagSearch true "分页获取用户标签列表"
// @Success 200 {object} response.Response{data=response.PageResult,msg=string} "获取成功"
// @Router /st/getStarTagList [get]
func (stApi *StarTagApi) GetStarTagList(c *gin.Context) {
    // 创建业务用Context
    ctx := c.Request.Context()

	var pageInfo starNoteReq.StarTagSearch
	err := c.ShouldBindQuery(&pageInfo)
	if err != nil {
		response.FailWithMessage(err.Error(), c)
		return
	}
	list, total, err := stService.GetStarTagInfoList(ctx,pageInfo)
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

// GetStarTagPublic 不需要鉴权的用户标签接口
// @Tags StarTag
// @Summary 不需要鉴权的用户标签接口
// @Accept application/json
// @Produce application/json
// @Success 200 {object} response.Response{data=object,msg=string} "获取成功"
// @Router /st/getStarTagPublic [get]
func (stApi *StarTagApi) GetStarTagPublic(c *gin.Context) {
    // 创建业务用Context
    ctx := c.Request.Context()

    // 此接口不需要鉴权
    // 示例为返回了一个固定的消息接口，一般本接口用于C端服务，需要自己实现业务逻辑
    stService.GetStarTagPublic(ctx)
    response.OkWithDetailed(gin.H{
       "info": "不需要鉴权的用户标签接口信息",
    }, "获取成功", c)
}
