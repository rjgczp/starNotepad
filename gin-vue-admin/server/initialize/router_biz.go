package initialize

import (
	"github.com/flipped-aurora/gin-vue-admin/server/router"
	"github.com/gin-gonic/gin"
)

func holder(routers ...*gin.RouterGroup) {
	_ = routers
	_ = router.RouterGroupApp
}
func initBizRouter(routers ...*gin.RouterGroup) {
	privateGroup := routers[0]
	publicGroup := routers[1]
	holder(publicGroup, privateGroup)
	{
		starNoteRouter := router.RouterGroupApp.StarNote
		starNoteRouter.InitUserAccountRouter(privateGroup, publicGroup)
		starNoteRouter.InitNoteModelRouter(privateGroup, publicGroup)
		starNoteRouter.InitStarTagRouter(privateGroup, publicGroup)
		starNoteRouter.InitHistoryDayRouter(privateGroup, publicGroup)
		starNoteRouter.InitUserFileRouter(privateGroup, publicGroup)
		starNoteRouter.InitNoteCategoryRouter(privateGroup, publicGroup)
		starNoteRouter.InitStarColorRouter(privateGroup, publicGroup) // 占位方法，保证文件可以正确加载，避免go空变量检测报错，请勿删除。
		starNoteRouter.InitProviderRouter(privateGroup, publicGroup)
	}
}
