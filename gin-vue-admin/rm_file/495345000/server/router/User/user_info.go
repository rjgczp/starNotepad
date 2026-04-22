package User

import (
	"github.com/flipped-aurora/gin-vue-admin/server/middleware"
	"github.com/gin-gonic/gin"
)

type UserInfoRouter struct {}

// InitUserInfoRouter 初始化 用户信息 路由信息
func (s *UserInfoRouter) InitUserInfoRouter(Router *gin.RouterGroup,PublicRouter *gin.RouterGroup) {
	userRouter := Router.Group("user").Use(middleware.OperationRecord())
	userRouterWithoutRecord := Router.Group("user")
	userRouterWithoutAuth := PublicRouter.Group("user")
	{
		userRouter.POST("createUserInfo", userApi.CreateUserInfo)   // 新建用户信息
		userRouter.DELETE("deleteUserInfo", userApi.DeleteUserInfo) // 删除用户信息
		userRouter.DELETE("deleteUserInfoByIds", userApi.DeleteUserInfoByIds) // 批量删除用户信息
		userRouter.PUT("updateUserInfo", userApi.UpdateUserInfo)    // 更新用户信息
	}
	{
		userRouterWithoutRecord.GET("findUserInfo", userApi.FindUserInfo)        // 根据ID获取用户信息
		userRouterWithoutRecord.GET("getUserInfoList", userApi.GetUserInfoList)  // 获取用户信息列表
	}
	{
	    userRouterWithoutAuth.GET("getUserInfoPublic", userApi.GetUserInfoPublic)  // 用户信息开放接口
	}
}
