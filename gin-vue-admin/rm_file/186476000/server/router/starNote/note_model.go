package starNote

import (
	"github.com/flipped-aurora/gin-vue-admin/server/middleware"
	"github.com/gin-gonic/gin"
)

type NoteModelRouter struct {}

// InitNoteModelRouter 初始化 记事本 路由信息
func (s *NoteModelRouter) InitNoteModelRouter(Router *gin.RouterGroup,PublicRouter *gin.RouterGroup) {
	evtRouter := Router.Group("evt").Use(middleware.OperationRecord())
	evtRouterWithoutRecord := Router.Group("evt")
	evtRouterWithoutAuth := PublicRouter.Group("evt")
	{
		evtRouter.POST("createNoteModel", evtApi.CreateNoteModel)   // 新建记事本
		evtRouter.DELETE("deleteNoteModel", evtApi.DeleteNoteModel) // 删除记事本
		evtRouter.DELETE("deleteNoteModelByIds", evtApi.DeleteNoteModelByIds) // 批量删除记事本
		evtRouter.PUT("updateNoteModel", evtApi.UpdateNoteModel)    // 更新记事本
	}
	{
		evtRouterWithoutRecord.GET("findNoteModel", evtApi.FindNoteModel)        // 根据ID获取记事本
		evtRouterWithoutRecord.GET("getNoteModelList", evtApi.GetNoteModelList)  // 获取记事本列表
	}
	{
	    evtRouterWithoutAuth.GET("getNoteModelPublic", evtApi.GetNoteModelPublic)  // 记事本开放接口
	}
}
