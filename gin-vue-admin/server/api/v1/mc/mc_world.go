package mc

import (
	
	"github.com/flipped-aurora/gin-vue-admin/server/global"
    "github.com/flipped-aurora/gin-vue-admin/server/model/common/response"
    "github.com/flipped-aurora/gin-vue-admin/server/model/mc"
    mcReq "github.com/flipped-aurora/gin-vue-admin/server/model/mc/request"
    "github.com/gin-gonic/gin"
    "go.uber.org/zap"
)

type McWorldApi struct {}



// CreateMcWorld 创建MC世界
// @Tags McWorld
// @Summary 创建MC世界
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body mc.McWorld true "创建MC世界"
// @Success 200 {object} response.Response{msg=string} "创建成功"
// @Router /mcworld/createMcWorld [post]
func (mcworldApi *McWorldApi) CreateMcWorld(c *gin.Context) {
    // 创建业务用Context
    ctx := c.Request.Context()

	var mcworld mc.McWorld
	err := c.ShouldBindJSON(&mcworld)
	if err != nil {
		response.FailWithMessage(err.Error(), c)
		return
	}
	err = mcworldService.CreateMcWorld(ctx,&mcworld)
	if err != nil {
        global.GVA_LOG.Error("创建失败!", zap.Error(err))
		response.FailWithMessage("创建失败:" + err.Error(), c)
		return
	}
    response.OkWithMessage("创建成功", c)
}

// DeleteMcWorld 删除MC世界
// @Tags McWorld
// @Summary 删除MC世界
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body mc.McWorld true "删除MC世界"
// @Success 200 {object} response.Response{msg=string} "删除成功"
// @Router /mcworld/deleteMcWorld [delete]
func (mcworldApi *McWorldApi) DeleteMcWorld(c *gin.Context) {
    // 创建业务用Context
    ctx := c.Request.Context()

	ID := c.Query("ID")
	err := mcworldService.DeleteMcWorld(ctx,ID)
	if err != nil {
        global.GVA_LOG.Error("删除失败!", zap.Error(err))
		response.FailWithMessage("删除失败:" + err.Error(), c)
		return
	}
	response.OkWithMessage("删除成功", c)
}

// DeleteMcWorldByIds 批量删除MC世界
// @Tags McWorld
// @Summary 批量删除MC世界
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Success 200 {object} response.Response{msg=string} "批量删除成功"
// @Router /mcworld/deleteMcWorldByIds [delete]
func (mcworldApi *McWorldApi) DeleteMcWorldByIds(c *gin.Context) {
    // 创建业务用Context
    ctx := c.Request.Context()

	IDs := c.QueryArray("IDs[]")
	err := mcworldService.DeleteMcWorldByIds(ctx,IDs)
	if err != nil {
        global.GVA_LOG.Error("批量删除失败!", zap.Error(err))
		response.FailWithMessage("批量删除失败:" + err.Error(), c)
		return
	}
	response.OkWithMessage("批量删除成功", c)
}

// UpdateMcWorld 更新MC世界
// @Tags McWorld
// @Summary 更新MC世界
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body mc.McWorld true "更新MC世界"
// @Success 200 {object} response.Response{msg=string} "更新成功"
// @Router /mcworld/updateMcWorld [put]
func (mcworldApi *McWorldApi) UpdateMcWorld(c *gin.Context) {
    // 从ctx获取标准context进行业务行为
    ctx := c.Request.Context()

	var mcworld mc.McWorld
	err := c.ShouldBindJSON(&mcworld)
	if err != nil {
		response.FailWithMessage(err.Error(), c)
		return
	}
	err = mcworldService.UpdateMcWorld(ctx,mcworld)
	if err != nil {
        global.GVA_LOG.Error("更新失败!", zap.Error(err))
		response.FailWithMessage("更新失败:" + err.Error(), c)
		return
	}
	response.OkWithMessage("更新成功", c)
}

// FindMcWorld 用id查询MC世界
// @Tags McWorld
// @Summary 用id查询MC世界
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param ID query uint true "用id查询MC世界"
// @Success 200 {object} response.Response{data=mc.McWorld,msg=string} "查询成功"
// @Router /mcworld/findMcWorld [get]
func (mcworldApi *McWorldApi) FindMcWorld(c *gin.Context) {
    // 创建业务用Context
    ctx := c.Request.Context()

	ID := c.Query("ID")
	remcworld, err := mcworldService.GetMcWorld(ctx,ID)
	if err != nil {
        global.GVA_LOG.Error("查询失败!", zap.Error(err))
		response.FailWithMessage("查询失败:" + err.Error(), c)
		return
	}
	response.OkWithData(remcworld, c)
}
// GetMcWorldList 分页获取MC世界列表
// @Tags McWorld
// @Summary 分页获取MC世界列表
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data query mcReq.McWorldSearch true "分页获取MC世界列表"
// @Success 200 {object} response.Response{data=response.PageResult,msg=string} "获取成功"
// @Router /mcworld/getMcWorldList [get]
func (mcworldApi *McWorldApi) GetMcWorldList(c *gin.Context) {
    // 创建业务用Context
    ctx := c.Request.Context()

	var pageInfo mcReq.McWorldSearch
	err := c.ShouldBindQuery(&pageInfo)
	if err != nil {
		response.FailWithMessage(err.Error(), c)
		return
	}
	list, total, err := mcworldService.GetMcWorldInfoList(ctx,pageInfo)
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

// GetMcWorldPublic 不需要鉴权的MC世界接口
// @Tags McWorld
// @Summary 不需要鉴权的MC世界接口
// @Accept application/json
// @Produce application/json
// @Success 200 {object} response.Response{data=object,msg=string} "获取成功"
// @Router /mcworld/getMcWorldPublic [get]
func (mcworldApi *McWorldApi) GetMcWorldPublic(c *gin.Context) {
    // 创建业务用Context
    ctx := c.Request.Context()

    // 此接口不需要鉴权
    // 示例为返回了一个固定的消息接口，一般本接口用于C端服务，需要自己实现业务逻辑
    mcworldService.GetMcWorldPublic(ctx)
    response.OkWithDetailed(gin.H{
       "info": "不需要鉴权的MC世界接口信息",
    }, "获取成功", c)
}
