package system

import (
	"strconv"

	"github.com/flipped-aurora/gin-vue-admin/server/global"
	"github.com/flipped-aurora/gin-vue-admin/server/model/common/response"
	"github.com/flipped-aurora/gin-vue-admin/server/model/system"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

type MainImageApi struct{}

func (a *MainImageApi) List(c *gin.Context) {
	images, err := mainImageService.List(c.Request.Context(), false)
	if err != nil {
		global.GVA_LOG.Error("获取主页图片失败", zap.Error(err))
		response.FailWithMessage("获取失败", c)
		return
	}
	response.OkWithData(images, c)
}

func (a *MainImageApi) PublicList(c *gin.Context) {
	images, err := mainImageService.List(c.Request.Context(), true)
	if err != nil {
		global.GVA_LOG.Error("获取公开主页图片失败", zap.Error(err))
		response.FailWithMessage("获取失败", c)
		return
	}
	response.OkWithData(images, c)
}

func (a *MainImageApi) Create(c *gin.Context) {
	var image system.MainImage
	if err := c.ShouldBindJSON(&image); err != nil {
		response.FailWithMessage(err.Error(), c)
		return
	}
	if err := mainImageService.Create(c.Request.Context(), &image); err != nil {
		response.FailWithMessage("创建失败: "+err.Error(), c)
		return
	}
	response.OkWithData(image, c)
}

func (a *MainImageApi) Update(c *gin.Context) {
	var image system.MainImage
	if err := c.ShouldBindJSON(&image); err != nil || image.ID == 0 {
		response.FailWithMessage("参数错误", c)
		return
	}
	if err := mainImageService.Update(c.Request.Context(), image); err != nil {
		response.FailWithMessage("更新失败: "+err.Error(), c)
		return
	}
	response.OkWithMessage("更新成功", c)
}

func (a *MainImageApi) Delete(c *gin.Context) {
	id, err := strconv.ParseUint(c.Query("ID"), 10, 64)
	if err != nil || id == 0 {
		response.FailWithMessage("参数错误", c)
		return
	}
	if err = mainImageService.Delete(c.Request.Context(), uint(id)); err != nil {
		response.FailWithMessage("删除失败: "+err.Error(), c)
		return
	}
	response.OkWithMessage("删除成功", c)
}
