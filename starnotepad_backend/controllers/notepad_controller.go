package controllers

import (
	"net/http"
	"starnotepad-backend/database"
	"starnotepad-backend/models"
	"time"

	"github.com/gin-gonic/gin"
)

type CreateNotepadRequest struct {
	Title      string    `json:"title" binding:"required"`
	Content    string    `json:"content" binding:"required"`
	CreatedAt  time.Time `json:"created_at" binding:"required"`
	CategoryID uint      `json:"category_id" binding:"required"`
	Icon       string    `json:"icon" binding:"required"`
	IsTop      bool      `json:"is_top" binding:"required"`
	Color      string    `json:"color" binding:"required"`
}

func CreateNotepad(c *gin.Context) {
	var req CreateNotepadRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "参数错误"})
		return
	}
	//从token中获取用户id
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"success": false, "message": "无法获取用户信息"})
		return
	}
	//创建记事本
	notepad := models.Notepad{
		UserID:     userID.(uint),
		CategoryID: req.CategoryID,
		Icon:       req.Icon,
		IsTop:      req.IsTop,
		Title:      req.Title,
		Content:    req.Content,
		CreatedAt:  req.CreatedAt,
		UpdatedAt:  req.CreatedAt,
		DeletedAt:  time.Time{},
		IsDeleted:  false,
		IsInform:   false,
		Color:      req.Color,
	}
	//保存记事本
	database.DB.Create(&notepad)
	c.JSON(http.StatusOK, gin.H{"success": true, "message": "记事本创建成功"})
}

func GetNotepadList(c *gin.Context) {
	//获取记事本列表
	notepadList := []models.Notepad{}
	database.DB.Find(&notepadList)
	c.JSON(http.StatusOK, gin.H{"success": true, "data": notepadList})
}
