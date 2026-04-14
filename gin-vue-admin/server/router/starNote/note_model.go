package starNote

import (
	"github.com/flipped-aurora/gin-vue-admin/server/middleware"
	"github.com/gin-gonic/gin"
)

type NoteModelRouter struct{}

// InitNoteModelRouter 初始化 记事本 路由信息
func (s *NoteModelRouter) InitNoteModelRouter(Router *gin.RouterGroup, PublicRouter *gin.RouterGroup) {
	evtRouter := Router.Group("evt").Use(middleware.OperationRecord())
	evtRouterWithoutRecord := Router.Group("evt")
	evtRouterWithoutAuth := PublicRouter.Group("evt")
	unoteRouter := PublicRouter.Group("unote").Use(middleware.JWTAuthHeaderOnlyRest())
	{
		evtRouter.POST("createNoteModel", evtApi.CreateNoteModel)             // 新建记事本
		evtRouter.DELETE("deleteNoteModel", evtApi.DeleteNoteModel)           // 删除记事本
		evtRouter.DELETE("deleteNoteModelByIds", evtApi.DeleteNoteModelByIds) // 批量删除记事本
		evtRouter.PUT("updateNoteModel", evtApi.UpdateNoteModel)              // 更新记事本
	}
	{
		evtRouterWithoutRecord.GET("findNoteModel", evtApi.FindNoteModel)       // 根据ID获取记事本
		evtRouterWithoutRecord.GET("getNoteModelList", evtApi.GetNoteModelList) // 获取记事本列表
	}
	{
		evtRouterWithoutAuth.GET("getNoteModelPublic", evtApi.GetNoteModelPublic) // 记事本开放接口
	}
	{
		unoteRouter.POST("create", evtApi.CreateUserNoteModel)   // 用户端新建记事本(仅本人)
		unoteRouter.DELETE("delete", evtApi.DeleteUserNoteModel) // 用户端删除记事本(仅本人)
		unoteRouter.PUT("update", evtApi.UpdateUserNoteModel)    // 用户端更新记事本(仅本人)
		unoteRouter.POST("update", evtApi.UpdateUserNoteModel)   // 用户端更新记事本(仅本人)
		unoteRouter.GET("find", evtApi.FindUserNoteModel)        // 用户端根据ID获取记事本(仅本人)
		unoteRouter.GET("list", evtApi.GetUserNoteModelList)     // 用户端获取记事本列表(仅本人)
		unoteRouter.GET("all", evtApi.GetUserNoteModelAll)       // 用户端获取名下所有记事本(仅本人)
		unoteRouter.GET("checkToken", evtApi.CheckToken)         // 检测 token 有效期
		unoteRouter.GET("statistics", evtApi.GetNoteStatistics)  // 获取记事本统计
		unoteRouter.GET("calendar", evtApi.GetNoteCalendar)      // 获取月度记事本日历
		unoteRouter.POST("polish", evtApi.PolishUserNoteText)    // 用户端AI润色
		unoteRouter.POST("sync/pull", evtApi.SyncUserNotesPull)  // 用户端拉取记事本增量同步
		unoteRouter.POST("sync/push", evtApi.SyncUserNotesPush)  // 用户端推送记事本增量同步
	}
}
