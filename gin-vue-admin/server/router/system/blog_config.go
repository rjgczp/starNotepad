package system

import (
	"github.com/flipped-aurora/gin-vue-admin/server/middleware"
	"github.com/gin-gonic/gin"
)

type UserBlog_configRouter struct {}

// InitUserBlog_configRouter 初始化 个人主页 路由信息
func (s *UserBlog_configRouter) InitUserBlog_configRouter(Router *gin.RouterGroup,PublicRouter *gin.RouterGroup) {
	bcRouter := Router.Group("bc").Use(middleware.OperationRecord())
	bcRouterWithoutRecord := Router.Group("bc")
	bcRouterWithoutAuth := PublicRouter.Group("bc")
	{
		bcRouter.POST("createUserBlog_config", bcApi.CreateUserBlog_config)   // 新建个人主页
		bcRouter.DELETE("deleteUserBlog_config", bcApi.DeleteUserBlog_config) // 删除个人主页
		bcRouter.DELETE("deleteUserBlog_configByIds", bcApi.DeleteUserBlog_configByIds) // 批量删除个人主页
		bcRouter.PUT("updateUserBlog_config", bcApi.UpdateUserBlog_config)    // 更新个人主页
	}
	{
		bcRouterWithoutRecord.GET("findUserBlog_config", bcApi.FindUserBlog_config)        // 根据ID获取个人主页
		bcRouterWithoutRecord.GET("getUserBlog_configList", bcApi.GetUserBlog_configList)  // 获取个人主页列表
	}
	{
	    bcRouterWithoutAuth.GET("getUserBlog_configPublic", bcApi.GetUserBlog_configPublic)  // 个人主页开放接口
	}
}
