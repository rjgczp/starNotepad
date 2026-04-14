package starNote

import (
	"github.com/flipped-aurora/gin-vue-admin/server/middleware"
	"github.com/gin-gonic/gin"
)

type UserFileRouter struct{}

// InitUserFileRouter 初始化 用户端文件上传下载 路由信息
func (s *UserFileRouter) InitUserFileRouter(Router *gin.RouterGroup, PublicRouter *gin.RouterGroup) {
	ufileRouter := PublicRouter.Group("ufile").Use(middleware.JWTAuthHeaderOnlyRest())
	{
		ufileRouter.POST("upload", ufApi.Upload)                  // 用户端上传文件/图片
		ufileRouter.GET("download", ufApi.Download)               // 用户端下载/访问文件(按id 302跳转)
		ufileRouter.GET("download/*filepath", ufApi.DownloadPath) // 用户端下载/访问文件(路径式，直接返回文件)
	}
}
