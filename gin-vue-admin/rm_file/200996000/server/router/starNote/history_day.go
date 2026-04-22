package starNote

import (
	"github.com/flipped-aurora/gin-vue-admin/server/middleware"
	"github.com/gin-gonic/gin"
)

type HistoryDayRouter struct {}

// InitHistoryDayRouter 初始化 历史上的今天 路由信息
func (s *HistoryDayRouter) InitHistoryDayRouter(Router *gin.RouterGroup,PublicRouter *gin.RouterGroup) {
	hdRouter := Router.Group("hd").Use(middleware.OperationRecord())
	hdRouterWithoutRecord := Router.Group("hd")
	hdRouterWithoutAuth := PublicRouter.Group("hd")
	{
		hdRouter.POST("createHistoryDay", hdApi.CreateHistoryDay)   // 新建历史上的今天
		hdRouter.DELETE("deleteHistoryDay", hdApi.DeleteHistoryDay) // 删除历史上的今天
		hdRouter.DELETE("deleteHistoryDayByIds", hdApi.DeleteHistoryDayByIds) // 批量删除历史上的今天
		hdRouter.PUT("updateHistoryDay", hdApi.UpdateHistoryDay)    // 更新历史上的今天
	}
	{
		hdRouterWithoutRecord.GET("findHistoryDay", hdApi.FindHistoryDay)        // 根据ID获取历史上的今天
		hdRouterWithoutRecord.GET("getHistoryDayList", hdApi.GetHistoryDayList)  // 获取历史上的今天列表
	}
	{
	    hdRouterWithoutAuth.GET("getHistoryDayPublic", hdApi.GetHistoryDayPublic)  // 历史上的今天开放接口
	}
}
