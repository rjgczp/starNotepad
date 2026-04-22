package starNote

import (
	"github.com/flipped-aurora/gin-vue-admin/server/middleware"
	"github.com/gin-gonic/gin"
)

type UserAccountRouter struct {}

// InitUserAccountRouter 初始化 用户账号 路由信息
func (s *UserAccountRouter) InitUserAccountRouter(Router *gin.RouterGroup,PublicRouter *gin.RouterGroup) {
	uaRouter := Router.Group("ua").Use(middleware.OperationRecord())
	uaRouterWithoutRecord := Router.Group("ua")
	uaRouterWithoutAuth := PublicRouter.Group("ua")
	{
		uaRouter.POST("createUserAccount", uaApi.CreateUserAccount)   // 新建用户账号
		uaRouter.DELETE("deleteUserAccount", uaApi.DeleteUserAccount) // 删除用户账号
		uaRouter.DELETE("deleteUserAccountByIds", uaApi.DeleteUserAccountByIds) // 批量删除用户账号
		uaRouter.PUT("updateUserAccount", uaApi.UpdateUserAccount)    // 更新用户账号
	}
	{
		uaRouterWithoutRecord.GET("findUserAccount", uaApi.FindUserAccount)        // 根据ID获取用户账号
		uaRouterWithoutRecord.GET("getUserAccountList", uaApi.GetUserAccountList)  // 获取用户账号列表
	}
	{
	    uaRouterWithoutAuth.GET("getUserAccountPublic", uaApi.GetUserAccountPublic)  // 用户账号开放接口
	}
}
