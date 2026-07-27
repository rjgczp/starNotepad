package starNote

import (
	"github.com/flipped-aurora/gin-vue-admin/server/middleware"
	"github.com/gin-gonic/gin"
)

type UserAccountRouter struct{}

// InitUserAccountRouter 初始化 用户账号 路由信息
func (s *UserAccountRouter) InitUserAccountRouter(Router *gin.RouterGroup, PublicRouter *gin.RouterGroup) {
	uaRouter := Router.Group("ua").Use(middleware.OperationRecord())
	uaRouterWithoutRecord := Router.Group("ua")
	adminRouter := Router.Group("admin")
	adminUsersRouter := adminRouter.Group("users")
	uaRouterUserAuth := PublicRouter.Group("ua").Use(middleware.JWTAuthHeaderOnlyRest())
	uaRouterWithoutAuth := PublicRouter.Group("ua")
	{
		uaRouter.POST("createUserAccount", uaApi.CreateUserAccount)             // 新建用户账号
		uaRouter.DELETE("deleteUserAccount", uaApi.DeleteUserAccount)           // 删除用户账号
		uaRouter.DELETE("deleteUserAccountByIds", uaApi.DeleteUserAccountByIds) // 批量删除用户账号
		uaRouter.PUT("updateUserAccount", uaApi.UpdateUserAccount)              // 更新用户账号
	}
	{
		uaRouterWithoutRecord.GET("findUserAccount", uaApi.FindUserAccount)       // 根据ID获取用户账号
		uaRouterWithoutRecord.GET("getUserAccountList", uaApi.GetUserAccountList) // 获取用户账号列表
	}
	{
		adminRouter.GET("tags", uaApi.GetAdminTags)                  // 管理端获取全量标签
		adminUsersRouter.GET(":id/tags", uaApi.GetAdminUserTags)     // 管理端获取用户标签
		adminUsersRouter.POST(":id/tags", uaApi.UpdateAdminUserTags) // 管理端更新用户标签
	}
	{
		uaRouterUserAuth.GET("getCurrentUserProfile", uaApi.GetCurrentUserProfile) // 获取当前登录用户信息（含标签）
		uaRouterUserAuth.PUT("updateCurrentUserProfile", uaApi.UpdateCurrentUserProfile)
	}
	{
		uaRouterWithoutAuth.POST("login", uaApi.Login)                                             // 用户账号登录
		uaRouterWithoutAuth.POST("loginVerify", uaApi.LoginVerify)                                 // 新设备登录邮箱验证
		uaRouterWithoutAuth.POST("register", uaApi.Register)                                       // 用户账号注册
		uaRouterWithoutAuth.POST("sendRegisterEmailCode", uaApi.SendRegisterEmailCode)             // 注册邮箱验证码
		uaRouterWithoutAuth.POST("sendChangePasswordEmailCode", uaApi.SendChangePasswordEmailCode) // 修改密码邮箱验证码
		uaRouterWithoutAuth.POST("changePassword", uaApi.ChangePassword)                           // 修改密码
		uaRouterWithoutAuth.GET("getUserAccountPublic", uaApi.GetUserAccountPublic)                // 用户账号开放接口
	}
}
