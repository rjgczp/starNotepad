package controllers

import (
	"net/http"
	"starnotepad-backend/database"
	"starnotepad-backend/models"
	"time"

	"github.com/gin-gonic/gin"
)

type CreateNotepadRequest struct {
	Title      string `json:"title" binding:"required"`
	Content    string `json:"content" binding:"required"`
	CategoryID uint   `json:"category_id" binding:"required"`
	Icon       string `json:"icon" binding:"required"`
	IsTop      bool   `json:"is_top"`
	Color      string `json:"color" binding:"required"`
}

type CreateNotepadCategoryRequest struct {
	Name  string `json:"name" binding:"required"`  //分类名称
	Icon  string `json:"icon" binding:"required"`  //分类图标
	Color string `json:"color" binding:"required"` //分类颜色
}

type UpdateNotepadRequest struct {
	ID          uint   `json:"id" binding:"required"`
	ContentHtml string `json:"content_html" binding:"required"`
	Content     string `json:"content" binding:"required"`
	Title       string `json:"title" binding:"required"`
	CategoryID  uint   `json:"category_id" binding:"required"`
	Icon        string `json:"icon" binding:"required"`
	IsTop       bool   `json:"is_top"`
	Color       string `json:"color" binding:"required"`
	IsInform    bool   `json:"is_inform"`
}

func CreateNotepadCategory(c *gin.Context) {
	var req CreateNotepadCategoryRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "参数错误", "error": err.Error()})
		return
	}
	//从token中获取用户id
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"success": false, "message": "无法获取用户信息"})
		return
	}
	//判断name是否存在
	notepadCategoryList := []models.NotepadCategory{}
	database.DB.Where("name = ?", req.Name).Find(&notepadCategoryList)
	if len(notepadCategoryList) > 0 {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "分类名称已存在"})
		return
	}

	//创建记事本分类
	notepadCategory := models.NotepadCategory{
		UserID:    userID.(uint),
		Name:      req.Name,
		Icon:      req.Icon,
		Color:     req.Color,
		IsDefault: false,
	}
	//保存记事本分类
	database.DB.Create(&notepadCategory)
	c.JSON(http.StatusOK, gin.H{"success": true, "message": "记事本分类创建成功"})
}

func GetNotepadCategoryList(c *gin.Context) {
	//获取记事本分类列表
	notepadCategoryList := []models.NotepadCategory{}
	database.DB.Find(&notepadCategoryList)
	c.JSON(http.StatusOK, gin.H{"success": true, "data": notepadCategoryList})
}

func GetDefaultNotepadCategoryList(c *gin.Context) {

	//获取默认的记事本分类列表
	notepadCategoryList := []models.NotepadCategory{}
	database.DB.Where("is_default = ?", true).Find(&notepadCategoryList)
	c.JSON(http.StatusOK, gin.H{"success": true, "data": notepadCategoryList})
}

func GetDefaultNotepadCategoryListByUserID(c *gin.Context) {
	//获取指定用户的默认记事本分类列表
	userID := c.Param("userID")
	notepadCategoryList := []models.NotepadCategory{}
	database.DB.Where("user_id = ? AND is_default = ?", userID, true).Find(&notepadCategoryList)
	c.JSON(http.StatusOK, gin.H{"success": true, "data": notepadCategoryList})
}

func CreateNotepad(c *gin.Context) {
	var req CreateNotepadRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "参数错误", "error": err.Error()})
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
		UserID:     userID.(uint),  //用户ID
		CategoryID: req.CategoryID, //分类ID
		Icon:       req.Icon,       //图标
		IsTop:      req.IsTop,      //是否置顶
		Title:      req.Title,      //标题
		Content:    req.Content,    //内容
		IsDeleted:  false,          //是否删除
		IsInform:   false,          //是否通知 默认不通知
		Color:      req.Color,      //颜色
	}
	//保存记事本
	database.DB.Create(&notepad)
	c.JSON(http.StatusOK, gin.H{"success": true, "message": "创建成功"})
}

func UpdateNotepad(c *gin.Context) {
	var req UpdateNotepadRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "参数错误", "error": err.Error()})
		return
	}
	//从token中获取用户id
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"success": false, "message": "无法获取用户信息", "error": "无法获取用户信息"})
		return
	}
	notepad := models.Notepad{}
	database.DB.Where("id = ? AND user_id = ?", req.ID, userID.(uint)).First(&notepad)
	notepad.ContentHtml = req.ContentHtml
	notepad.Content = req.Content
	notepad.Title = req.Title
	notepad.CategoryID = req.CategoryID
	notepad.Icon = req.Icon
	notepad.IsTop = req.IsTop
	notepad.Color = req.Color
	database.DB.Save(&notepad)
	c.JSON(http.StatusOK, gin.H{"success": true, "message": "更新成功"})
}

func GetNotepadList(c *gin.Context) {
	//根据用户的id获取记事本列表
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"success": false, "message": "无法获取用户信息", "error": "无法获取用户信息"})
		return
	}
	notepadList := []models.Notepad{}
	database.DB.Where("user_id = ?", userID.(uint)).Find(&notepadList)
	c.JSON(http.StatusOK, gin.H{"success": true, "data": notepadList})
}

func GetNotepadListByCategoryID(c *gin.Context) {
	//根据分类id获取记事本列表
	categoryID := c.Param("categoryID")
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"success": false, "message": "无法获取用户信息", "error": "无法获取用户信息"})
		return
	}
	notepadList := []models.Notepad{}
	database.DB.Where("user_id = ? AND category_id = ?", userID.(uint), categoryID).Find(&notepadList)
	c.JSON(http.StatusOK, gin.H{"success": true, "data": notepadList})
}

func SearchNotepadByKeyword(c *gin.Context) {
	//根据关键词模糊查询记事本列表
	keyword := c.Param("keyword")
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"success": false, "message": "无法获取用户信息", "error": "无法获取用户信息"})
		return
	}
	notepadList := []models.Notepad{}
	database.DB.Where("user_id = ? AND (title LIKE ? OR content LIKE ?)", userID.(uint), "%"+keyword+"%", "%"+keyword+"%").Find(&notepadList)
	c.JSON(http.StatusOK, gin.H{"success": true, "data": notepadList})
}

func GetDeletedNotepadList(c *gin.Context) {
	//获取回收站中的记事本列表
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"success": false, "message": "无法获取用户信息", "error": "无法获取用户信息"})
		return
	}
	notepadList := []models.Notepad{}
	database.DB.Where("user_id = ? AND is_deleted = ?", userID.(uint), true).Find(&notepadList)
	c.JSON(http.StatusOK, gin.H{"success": true, "data": notepadList})
}

func UpdateNotepadDeleteStatus(c *gin.Context) {
	//修改删除状态
	notepadID := c.Param("id")
	deleteStatus := c.Param("deleteStatus")
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"success": false, "message": "无法获取用户信息", "error": "无法获取用户信息"})
		return
	}
	notepad := models.Notepad{}
	database.DB.Where("id = ? AND user_id = ?", notepadID, userID.(uint)).First(&notepad)
	notepad.IsDeleted = deleteStatus == "true"
	if notepad.IsDeleted {
		notepad.DeletedAt = &time.Time{}
	} else {
		notepad.DeletedAt = &time.Time{}
	}
	database.DB.Save(&notepad)
	message := ""
	if notepad.IsDeleted {
		message = "恢复成功"
	} else {
		message = "移入回收站成功"
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "message": message})
}

func DeleteNotepad(c *gin.Context) {
	//删除记事本
	notepadID := c.Param("id")
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"success": false, "message": "无法获取用户信息", "error": "无法获取用户信息"})
		return
	}
	notepad := models.Notepad{}
	database.DB.Where("id = ? AND user_id = ?", notepadID, userID.(uint)).First(&notepad)
	database.DB.Delete(&notepad)
	c.JSON(http.StatusOK, gin.H{"success": true, "message": "删除成功"})
}
