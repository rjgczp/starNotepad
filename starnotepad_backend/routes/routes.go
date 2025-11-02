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
		auth.POST("/addLoginDevice", controllers.AddLoginDevice)   //添加登录设备
		auth.POST("/sendEmailCode", controllers.SendEmailCode)     //发送邮箱验证码
		auth.POST("/verifyEmailCode", controllers.VerifyEmailCode) //验证邮箱验证码
	}
	//用户相关路由
	user := r.Group("/api/user") //用户相关路由，需要认证中间件
	user.Use(middleware.AuthMiddleware())
	{
		user.GET("/info", controllers.GetUserInfo)               //获取用户信息
		user.POST("/updateUserInfo", controllers.UpdateUserInfo) //更新用户信息
		user.POST("/changePassword", controllers.ChangePassword) //修改密码
		user.POST("/deleteAccount", controllers.DeleteAccount)   //注销用户
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
		notepad.POST("/create", controllers.CreateNotepad)                                           //创建记事本
		notepad.POST("/update/:id", controllers.UpdateNotepad)                                       //更新记事本
		notepad.POST("/updateDeleteStatus/:id/:deleteStatus", controllers.UpdateNotepadDeleteStatus) //移入回收站或恢复记事本
		notepad.GET("/deletedList", controllers.GetDeletedNotepadList)                               //获取回收站中的记事本列表
		notepad.DELETE("/delete/:id", controllers.DeleteNotepad)                                     //删除记事本
		notepad.GET("/list", controllers.GetNotepadList)                                             //获取记事本列表
		notepad.GET("/listByCategory/:categoryID", controllers.GetNotepadListByCategoryID)           //获取指定分类的记事本列表
		notepad.GET("/search/:keyword", controllers.SearchNotepadByKeyword)                          //模糊查询记事本
	}
	//记事本分类
	notepadCategory := r.Group("/api/notepadCategory") //记事本分类相关路由，需要认证中间件
	notepadCategory.Use(middleware.AuthMiddleware())
	{
		notepadCategory.POST("/create", controllers.CreateNotepadCategory)                             //创建记事本分类
		notepadCategory.GET("/list", controllers.GetNotepadCategoryList)                               //获取记事本分类列表
		notepadCategory.GET("/defaultList", controllers.GetDefaultNotepadCategoryList)                 //获取默认的记事本分类列表
		notepadCategory.GET("/defaultList/:userID", controllers.GetDefaultNotepadCategoryListByUserID) //获取指定用户的默认记事本分类列表
	}
	//会员系统
	member := r.Group("/api/member") //会员系统相关路由，需要认证中间件
	member.Use(middleware.AuthMiddleware())
	{
		member.POST("/create", controllers.CreateMember) //创建会员
		member.GET("/list", controllers.GetMemberList)   //获取会员列表
		member.GET("/isMember", controllers.IsMember)    //查询该用户是否为会员
		member.POST("/renew", controllers.RenewMember)   //续费会员
	}
	//今日历史
	todayInHistory := r.Group("/api/todayInHistory") //今日历史相关路由，需要认证中间件
	todayInHistory.Use(middleware.AuthMiddleware())
	{
		todayInHistory.GET("/info", controllers.GetTodayInHistoryInfo) //获取今日历史信息

	}

	//网络健康检查
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status": "ok",
		})
	})
}
