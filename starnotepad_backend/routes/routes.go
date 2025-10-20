package routes

import (
	"starnotepad-backend/controllers"
	"starnotepad-backend/middleware"

	"github.com/gin-gonic/gin"
)

func SetupRoutes(r *gin.Engine) {
	auth := r.Group("/api/auth") //认证相关路由
	{
		auth.POST("/register", controllers.Register)               //用户注册
		auth.POST("/login", controllers.Login)                     //用户登录
		auth.POST("/sendEmailCode", controllers.SendEmailCode)     //发送邮箱验证码
		auth.POST("/verifyEmailCode", controllers.VerifyEmailCode) //验证邮箱验证码
	}
	//用户相关路由
	user := r.Group("/api/user") //用户相关路由，需要认证中间件
	user.Use(middleware.AuthMiddleware())
	{
		user.GET("/info", controllers.GetUserInfo)               //获取用户信息
		user.POST("/changePassword", controllers.ChangePassword) //修改密码
	}
	//通用相关路由
	common := r.Group("/api/common") //通用相关路由
	common.Use(middleware.AuthMiddleware())
	{
		//文件上传
		common.POST("/upload", controllers.UploadFile)         //上传文件
		common.GET("/getFile/:file", controllers.DownloadFile) //下载文件
	}

	//记事本相关路由
	notepad := r.Group("/api/notepad") //记事本相关路由，需要认证中间件
	notepad.Use(middleware.AuthMiddleware())
	{
		notepad.POST("/create", controllers.CreateNotepad) //创建记事本
		notepad.GET("/list", controllers.GetNotepadList)   //获取记事本列表
	}

	//网络健康检查
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status": "ok",
		})
	})
}
