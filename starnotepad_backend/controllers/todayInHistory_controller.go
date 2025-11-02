package controllers

import (
	"net/http"
	"starnotepad-backend/database"
	"starnotepad-backend/models"

	"github.com/gin-gonic/gin"
)

func GetTodayInHistoryInfo(c *gin.Context) {
	//获取今日历史信息
	date := c.Query("date")
	var todayInHistory models.TodayInHistory
	if err := database.DB.Where("date = ?", date).First(&todayInHistory).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "今日历史信息不存在", "error": "今日历史信息不存在"})
		return
	}
	var todayEvents []models.TodayEvent
	if err := database.DB.Where("today_in_history_id = ?", todayInHistory.ID).Find(&todayEvents).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "今日事件信息不存在", "error": "今日事件信息不存在"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "message": "今日历史信息获取成功", "data": todayInHistory})
}
