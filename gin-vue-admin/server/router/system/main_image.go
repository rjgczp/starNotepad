package system

import (
	"github.com/flipped-aurora/gin-vue-admin/server/middleware"
	"github.com/gin-gonic/gin"
)

type MainImageRouter struct{}

func (r *MainImageRouter) InitMainImageRouter(private, public *gin.RouterGroup) {
	withRecord := private.Group("mainImage").Use(middleware.OperationRecord())
	withoutRecord := private.Group("mainImage")
	{
		withRecord.POST("create", mainImageApi.Create)
		withRecord.PUT("update", mainImageApi.Update)
		withRecord.DELETE("delete", mainImageApi.Delete)
		withoutRecord.GET("list", mainImageApi.List)
		public.GET("mainImage/public", mainImageApi.PublicList)
	}
}
