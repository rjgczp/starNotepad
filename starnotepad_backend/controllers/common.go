package controllers

import (
	"net/http"
	"os"
	"path/filepath"

	"github.com/gin-gonic/gin"
)

func UploadFile(c *gin.Context) {
	//获取文件
	file, err := c.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "文件上传失败", "error": err.Error()})
		return
	}
	//保存文件
	// 确保上传目录存在
	if err := os.MkdirAll("assets", 0755); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "文件上传失败", "error": err.Error()})
		return
	}
	// 基础化文件名，防止目录穿越
	//放在assets文件夹中
	safeName := filepath.Base(file.Filename)
	filePath := filepath.Join("assets", safeName)
	if err := c.SaveUploadedFile(file, filePath); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "文件上传失败", "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "message": "文件上传成功", "data": gin.H{"url": filePath}})
}

func DownloadFile(c *gin.Context) {
	//获取文件名
	fileName := c.Param("file")
	// 基础化文件名，防止目录穿越
	safeName := filepath.Base(fileName)
	fullPath := filepath.Join("assets", safeName)
	if _, err := os.Stat(fullPath); err != nil {
		if os.IsNotExist(err) {
			c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "文件不存在", "error": "文件不存在"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "文件下载失败", "error": err.Error()})
		return
	}
	// 下载文件
	c.File(fullPath)
}
