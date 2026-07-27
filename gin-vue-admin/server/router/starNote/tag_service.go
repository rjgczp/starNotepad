package starNote

import (
	"github.com/flipped-aurora/gin-vue-admin/server/middleware"
	"github.com/gin-gonic/gin"
)

type StarTagRouter struct {}

// InitStarTagRouter 初始化 用户标签 路由信息
func (s *StarTagRouter) InitStarTagRouter(Router *gin.RouterGroup,PublicRouter *gin.RouterGroup) {
	stRouter := Router.Group("st").Use(middleware.OperationRecord())
	stRouterWithoutRecord := Router.Group("st")
	stRouterWithoutAuth := PublicRouter.Group("st")
	{
		stRouter.POST("createStarTag", stApi.CreateStarTag)   // 新建用户标签
		stRouter.DELETE("deleteStarTag", stApi.DeleteStarTag) // 删除用户标签
		stRouter.DELETE("deleteStarTagByIds", stApi.DeleteStarTagByIds) // 批量删除用户标签
		stRouter.PUT("updateStarTag", stApi.UpdateStarTag)    // 更新用户标签
	}
	{
		stRouterWithoutRecord.GET("findStarTag", stApi.FindStarTag)        // 根据ID获取用户标签
		stRouterWithoutRecord.GET("getStarTagList", stApi.GetStarTagList)  // 获取用户标签列表
	}
	{
	    stRouterWithoutAuth.GET("getStarTagPublic", stApi.GetStarTagPublic)  // 用户标签开放接口
	}
}
