package starNote

import (
	"github.com/flipped-aurora/gin-vue-admin/server/middleware"
	"github.com/gin-gonic/gin"
)

type ProviderRouter struct{}

// InitProviderRouter 初始化 AI供应商 路由信息
func (s *ProviderRouter) InitProviderRouter(Router *gin.RouterGroup, PublicRouter *gin.RouterGroup) {
	aiProviderRouter := Router.Group("aiProvider").Use(middleware.OperationRecord())
	aiProviderRouterWithoutRecord := Router.Group("aiProvider")
	aiProviderRouterWithoutAuth := PublicRouter.Group("aiProvider")
	{
		aiProviderRouter.POST("createProvider", aiProviderApi.CreateProvider)             // 新建AI供应商
		aiProviderRouter.DELETE("deleteProvider", aiProviderApi.DeleteProvider)           // 删除AI供应商
		aiProviderRouter.DELETE("deleteProviderByIds", aiProviderApi.DeleteProviderByIds) // 批量删除AI供应商
		aiProviderRouter.PUT("updateProvider", aiProviderApi.UpdateProvider)              // 更新AI供应商
	}
	{
		aiProviderRouterWithoutRecord.GET("findProvider", aiProviderApi.FindProvider)       // 根据ID获取AI供应商
		aiProviderRouterWithoutRecord.GET("getProviderList", aiProviderApi.GetProviderList) // 获取AI供应商列表
	}
	{
		aiProviderRouterWithoutAuth.GET("getProviderPublic", aiProviderApi.GetProviderPublic)        // AI供应商开放接口
		aiProviderRouterWithoutAuth.POST("invokeActiveProvider", aiProviderApi.InvokeActiveProvider) // 调用当前启用AI供应商
	}
}
