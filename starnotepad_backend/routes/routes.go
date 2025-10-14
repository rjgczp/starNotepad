package routes

import (
	"starnotepad-backend/controllers"
	"starnotepad-backend/middleware"

	"github.com/gin-gonic/gin"
)

func SetupRoutes(r *gin.Engine) {
	// 认证相关路由
	auth := r.Group("/api/auth")
	{
		auth.POST("/register", controllers.Register)
		auth.POST("/login", controllers.Login)
		//通过邮箱发送验证码
		auth.POST("/sendEmailCode", controllers.SendEmailCode)
	}
	//用户相关路由
	user := r.Group("/api/user")
	user.Use(middleware.AuthMiddleware())
	{
		user.GET("/info", controllers.GetUserInfo)
	}

	// 网络健康检查
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status": "ok",
		})
	})
}
