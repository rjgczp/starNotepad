package starNote

import (
	"github.com/flipped-aurora/gin-vue-admin/server/middleware"
	"github.com/gin-gonic/gin"
)

type NoteCategoryRouter struct {}

// InitNoteCategoryRouter 初始化 记事本分类管理 路由信息
func (s *NoteCategoryRouter) InitNoteCategoryRouter(Router *gin.RouterGroup,PublicRouter *gin.RouterGroup) {
	ncRouter := Router.Group("nc").Use(middleware.OperationRecord())
	ncRouterWithoutRecord := Router.Group("nc")
	ncRouterWithoutAuth := PublicRouter.Group("nc")
	{
		ncRouter.POST("createNoteCategory", ncApi.CreateNoteCategory)   // 新建记事本分类管理
		ncRouter.DELETE("deleteNoteCategory", ncApi.DeleteNoteCategory) // 删除记事本分类管理
		ncRouter.DELETE("deleteNoteCategoryByIds", ncApi.DeleteNoteCategoryByIds) // 批量删除记事本分类管理
		ncRouter.PUT("updateNoteCategory", ncApi.UpdateNoteCategory)    // 更新记事本分类管理
	}
	{
		ncRouterWithoutRecord.GET("findNoteCategory", ncApi.FindNoteCategory)        // 根据ID获取记事本分类管理
		ncRouterWithoutRecord.GET("getNoteCategoryList", ncApi.GetNoteCategoryList)  // 获取记事本分类管理列表
	}
	{
	    ncRouterWithoutAuth.GET("getNoteCategoryPublic", ncApi.GetNoteCategoryPublic)  // 记事本分类管理开放接口
	}
}
