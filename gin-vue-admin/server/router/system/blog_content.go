package system

import (
	"github.com/flipped-aurora/gin-vue-admin/server/middleware"
	"github.com/gin-gonic/gin"
)

type BlogContentRouter struct{}

func (r *BlogContentRouter) InitBlogContentRouter(private, public *gin.RouterGroup) {
	withRecord := private.Group("blogContent").Use(middleware.OperationRecord())
	withoutRecord := private.Group("blogContent")
	withoutRecord.GET("list", blogContentApi.List)
	withRecord.POST("post", blogContentApi.CreatePost)
	withRecord.PUT("post", blogContentApi.UpdatePost)
	withRecord.POST("skill", blogContentApi.CreateSkill)
	withRecord.PUT("skill", blogContentApi.UpdateSkill)
	withRecord.POST("project", blogContentApi.CreateProject)
	withRecord.PUT("project", blogContentApi.UpdateProject)
	withRecord.POST("experience", blogContentApi.CreateExperience)
	withRecord.PUT("experience", blogContentApi.UpdateExperience)
	withRecord.DELETE("delete", blogContentApi.Delete)
	public.GET("blogContent/public", blogContentApi.Public)
}
