package starNote

import (
	"github.com/flipped-aurora/gin-vue-admin/server/middleware"
	"github.com/gin-gonic/gin"
)

type StarColorRouter struct{}

// InitStarColorRouter 初始化 星颜色 路由信息
func (s *StarColorRouter) InitStarColorRouter(Router *gin.RouterGroup, PublicRouter *gin.RouterGroup) {
	scRouter := Router.Group("sc").Use(middleware.OperationRecord())
	scRouterWithoutRecord := Router.Group("sc")
	scRouterWithoutAuth := PublicRouter.Group("sc")
	userStarColorRouter := PublicRouter.Group("uscolor").Use(middleware.JWTAuthHeaderOnlyRest())
	{
		scRouter.POST("createStarColor", scApi.CreateStarColor)             // 新建星颜色
		scRouter.DELETE("deleteStarColor", scApi.DeleteStarColor)           // 删除星颜色
		scRouter.DELETE("deleteStarColorByIds", scApi.DeleteStarColorByIds) // 批量删除星颜色
		scRouter.PUT("updateStarColor", scApi.UpdateStarColor)              // 更新星颜色
	}
	{
		scRouterWithoutRecord.GET("findStarColor", scApi.FindStarColor)       // 根据ID获取星颜色
		scRouterWithoutRecord.GET("getStarColorList", scApi.GetStarColorList) // 获取星颜色列表
	}
	{
		scRouterWithoutAuth.GET("getStarColorPublic", scApi.GetStarColorPublic) // 星颜色开放接口
	}
	{
		userStarColorRouter.POST("create", scApi.CreateUserStarColor)   // 用户端添加颜色(仅本人)
		userStarColorRouter.GET("list", scApi.GetUserStarColorList)     // 用户端查询颜色(系统+本人)
		userStarColorRouter.PUT("update", scApi.UpdateUserStarColor)    // 用户端修改颜色(仅本人)
		userStarColorRouter.DELETE("delete", scApi.DeleteUserStarColor) // 用户端删除颜色(仅本人)
	}
}
