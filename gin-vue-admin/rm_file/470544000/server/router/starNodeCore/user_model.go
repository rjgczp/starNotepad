package starNodeCore

import (
	"github.com/flipped-aurora/gin-vue-admin/server/middleware"
	"github.com/gin-gonic/gin"
)

type UserInfoRouter struct {}

// InitUserInfoRouter 初始化 用户信息 路由信息
func (s *UserInfoRouter) InitUserInfoRouter(Router *gin.RouterGroup,PublicRouter *gin.RouterGroup) {
	usrRouter := Router.Group("usr").Use(middleware.OperationRecord())
	usrRouterWithoutRecord := Router.Group("usr")
	usrRouterWithoutAuth := PublicRouter.Group("usr")
	{
		usrRouter.POST("createUserInfo", usrApi.CreateUserInfo)   // 新建用户信息
		usrRouter.DELETE("deleteUserInfo", usrApi.DeleteUserInfo) // 删除用户信息
		usrRouter.DELETE("deleteUserInfoByIds", usrApi.DeleteUserInfoByIds) // 批量删除用户信息
		usrRouter.PUT("updateUserInfo", usrApi.UpdateUserInfo)    // 更新用户信息
	}
	{
		usrRouterWithoutRecord.GET("findUserInfo", usrApi.FindUserInfo)        // 根据ID获取用户信息
		usrRouterWithoutRecord.GET("getUserInfoList", usrApi.GetUserInfoList)  // 获取用户信息列表
	}
	{
	    usrRouterWithoutAuth.GET("getUserInfoPublic", usrApi.GetUserInfoPublic)  // 用户信息开放接口
	}
}
