package system

import (
	"strconv"

	"github.com/flipped-aurora/gin-vue-admin/server/global"
	"github.com/flipped-aurora/gin-vue-admin/server/model/common/response"
	"github.com/flipped-aurora/gin-vue-admin/server/model/system"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

type BlogContentApi struct{}

func (a *BlogContentApi) List(c *gin.Context) {
	posts, skills, projects, experiences, err := blogContentService.List(c.Request.Context())
	if err != nil {
		response.FailWithMessage("获取博客内容失败", c)
		return
	}
	response.OkWithData(gin.H{"posts": posts, "skills": skills, "projects": projects, "experiences": experiences}, c)
}

func (a *BlogContentApi) Public(c *gin.Context) {
	posts, skills, projects, experiences, err := blogContentService.Public(c.Request.Context())
	if err != nil {
		global.GVA_LOG.Error("获取公开博客内容失败", zap.Error(err))
		response.FailWithMessage("获取失败", c)
		return
	}
	response.OkWithData(gin.H{"posts": posts, "skills": skills, "projects": projects, "experiences": experiences}, c)
}

func (a *BlogContentApi) CreatePost(c *gin.Context) {
	var item system.BlogPost
	if c.ShouldBindJSON(&item) != nil {
		response.FailWithMessage("参数错误", c)
		return
	}
	if err := global.GVA_DB.WithContext(c.Request.Context()).Create(&item).Error; err != nil {
		response.FailWithMessage("创建失败: "+err.Error(), c)
		return
	}
	response.OkWithData(item, c)
}
func (a *BlogContentApi) UpdatePost(c *gin.Context) {
	var item system.BlogPost
	if c.ShouldBindJSON(&item) != nil || item.ID == 0 {
		response.FailWithMessage("参数错误", c)
		return
	}
	if err := global.GVA_DB.WithContext(c.Request.Context()).Save(&item).Error; err != nil {
		response.FailWithMessage("更新失败: "+err.Error(), c)
		return
	}
	response.OkWithMessage("更新成功", c)
}
func (a *BlogContentApi) CreateSkill(c *gin.Context) {
	var item system.BlogSkill
	if c.ShouldBindJSON(&item) != nil {
		response.FailWithMessage("参数错误", c)
		return
	}
	if err := global.GVA_DB.WithContext(c.Request.Context()).Create(&item).Error; err != nil {
		response.FailWithMessage("创建失败: "+err.Error(), c)
		return
	}
	response.OkWithData(item, c)
}
func (a *BlogContentApi) UpdateSkill(c *gin.Context) {
	var item system.BlogSkill
	if c.ShouldBindJSON(&item) != nil || item.ID == 0 {
		response.FailWithMessage("参数错误", c)
		return
	}
	if err := global.GVA_DB.WithContext(c.Request.Context()).Save(&item).Error; err != nil {
		response.FailWithMessage("更新失败: "+err.Error(), c)
		return
	}
	response.OkWithMessage("更新成功", c)
}
func (a *BlogContentApi) CreateProject(c *gin.Context) {
	var item system.BlogProject
	if c.ShouldBindJSON(&item) != nil {
		response.FailWithMessage("参数错误", c)
		return
	}
	if err := global.GVA_DB.WithContext(c.Request.Context()).Create(&item).Error; err != nil {
		response.FailWithMessage("创建失败: "+err.Error(), c)
		return
	}
	response.OkWithData(item, c)
}
func (a *BlogContentApi) UpdateProject(c *gin.Context) {
	var item system.BlogProject
	if c.ShouldBindJSON(&item) != nil || item.ID == 0 {
		response.FailWithMessage("参数错误", c)
		return
	}
	if err := global.GVA_DB.WithContext(c.Request.Context()).Save(&item).Error; err != nil {
		response.FailWithMessage("更新失败: "+err.Error(), c)
		return
	}
	response.OkWithMessage("更新成功", c)
}
func (a *BlogContentApi) CreateExperience(c *gin.Context) {
	var item system.BlogExperience
	if c.ShouldBindJSON(&item) != nil {
		response.FailWithMessage("参数错误", c)
		return
	}
	if err := global.GVA_DB.WithContext(c.Request.Context()).Create(&item).Error; err != nil {
		response.FailWithMessage("创建失败: "+err.Error(), c)
		return
	}
	response.OkWithData(item, c)
}
func (a *BlogContentApi) UpdateExperience(c *gin.Context) {
	var item system.BlogExperience
	if c.ShouldBindJSON(&item) != nil || item.ID == 0 {
		response.FailWithMessage("参数错误", c)
		return
	}
	if err := global.GVA_DB.WithContext(c.Request.Context()).Save(&item).Error; err != nil {
		response.FailWithMessage("更新失败: "+err.Error(), c)
		return
	}
	response.OkWithMessage("更新成功", c)
}

func (a *BlogContentApi) Delete(c *gin.Context) {
	id, err := strconv.ParseUint(c.Query("ID"), 10, 64)
	kind := c.Query("kind")
	if err != nil || id == 0 {
		response.FailWithMessage("参数错误", c)
		return
	}
	var model interface{}
	switch kind {
	case "post":
		model = &system.BlogPost{}
	case "skill":
		model = &system.BlogSkill{}
	case "project":
		model = &system.BlogProject{}
	case "experience":
		model = &system.BlogExperience{}
	default:
		response.FailWithMessage("未知内容类型", c)
		return
	}
	if err = global.GVA_DB.WithContext(c.Request.Context()).Delete(model, uint(id)).Error; err != nil {
		response.FailWithMessage("删除失败: "+err.Error(), c)
		return
	}
	response.OkWithMessage("删除成功", c)
}
