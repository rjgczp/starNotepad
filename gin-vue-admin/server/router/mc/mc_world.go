package mc

import (
	"github.com/flipped-aurora/gin-vue-admin/server/middleware"
	"github.com/gin-gonic/gin"
)

type McWorldRouter struct {}

// InitMcWorldRouter 初始化 MC世界 路由信息
func (s *McWorldRouter) InitMcWorldRouter(Router *gin.RouterGroup,PublicRouter *gin.RouterGroup) {
	mcworldRouter := Router.Group("mcworld").Use(middleware.OperationRecord())
	mcworldRouterWithoutRecord := Router.Group("mcworld")
	mcworldRouterWithoutAuth := PublicRouter.Group("mcworld")
	{
		mcworldRouter.POST("createMcWorld", mcworldApi.CreateMcWorld)   // 新建MC世界
		mcworldRouter.DELETE("deleteMcWorld", mcworldApi.DeleteMcWorld) // 删除MC世界
		mcworldRouter.DELETE("deleteMcWorldByIds", mcworldApi.DeleteMcWorldByIds) // 批量删除MC世界
		mcworldRouter.PUT("updateMcWorld", mcworldApi.UpdateMcWorld)    // 更新MC世界
	}
	{
		mcworldRouterWithoutRecord.GET("findMcWorld", mcworldApi.FindMcWorld)        // 根据ID获取MC世界
		mcworldRouterWithoutRecord.GET("getMcWorldList", mcworldApi.GetMcWorldList)  // 获取MC世界列表
	}
	{
	    mcworldRouterWithoutAuth.GET("getMcWorldPublic", mcworldApi.GetMcWorldPublic)  // MC世界开放接口
	}
}
