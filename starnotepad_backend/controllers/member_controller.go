package controllers

import (
	"net/http"
	"starnotepad-backend/database"
	"starnotepad-backend/models"
	"time"

	"github.com/gin-gonic/gin"
)

// 创建会员
type CreateMemberRequest struct {
	//充值金额
	RechargeAmount float64 `json:"recharge_amount" binding:"required"`
}

type UpdateMemberRequest struct {
	//充值金额
	RechargeAmount float64 `json:"recharge_amount" binding:"required"`
	//会员状态
	MemberStatus string `json:"member_status" binding:"required"`
}

// 创建会员
func CreateMember(c *gin.Context) {
	var req CreateMemberRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	//判断金额确定会员时长
	var memberDuration int
	if req.RechargeAmount >= 100 {
		memberDuration = 30
	} else if req.RechargeAmount >= 50 {
		memberDuration = 15
	} else {
		memberDuration = 7
	}
	member := models.Member{
		UserID:            uint(c.GetUint("user_id")),
		RechargeAmount:    req.RechargeAmount,
		MemberStatus:      "1",
		MemberExpiredTime: time.Now().AddDate(0, 0, memberDuration),
	}
	if err := database.DB.Create(&member).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "message": "会员创建成功"})
}

// 获取会员列表
func GetMemberList(c *gin.Context) {
	var members []models.Member
	if err := database.DB.Find(&members).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "无法获取会员列表"})
		return
	}
	//判断是否为管理员
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"success": false, "message": "无法获取用户信息"})
		return
	}
	var user models.User
	if err := database.DB.Where("id = ?", userID).First(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "无法获取用户信息"})
		return
	}
	if !user.IsAdmin {
		c.JSON(http.StatusUnauthorized, gin.H{"success": false, "message": "您没有权限获取会员列表"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": members})
}

// 查询该用户是否为会员
func IsMember(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"success": false, "message": "无法获取用户信息"})
		return
	}
	var member models.Member
	if err := database.DB.Where("user_id = ?", userID).First(&member).Error; err != nil {
		c.JSON(http.StatusOK, gin.H{"success": false, "message": "您不是会员"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": member})
}

// 更新会员
func RenewMember(c *gin.Context) {
	var req UpdateMemberRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "参数错误", "error": err.Error()})
		return
	}
	//判断金额确定会员时长
	var memberDuration int
	if req.RechargeAmount >= 100 {
		memberDuration = 30
	} else if req.RechargeAmount >= 50 {
		memberDuration = 15
	} else {
		memberDuration = 7
	}
	//更新会员
	member := models.Member{
		UserID:            uint(c.GetUint("user_id")),
		RechargeAmount:    req.RechargeAmount,
		MemberStatus:      req.MemberStatus,
		MemberExpiredTime: time.Now().AddDate(0, 0, memberDuration),
	}
	if err := database.DB.Save(&member).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "更新会员失败", "error": err.Error()})
		return
	}
}
