package controllers

import (
	"math/rand"
	"net/http"
	"starnotepad-backend/database"
	"starnotepad-backend/models"
	"starnotepad-backend/utils"
	"time"

	"github.com/gin-gonic/gin"
	"gopkg.in/gomail.v2"
)

type RegisterRequest struct {
	Username string `json:"username" binding:"required"`
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required,min=6"`
	Code     string `json:"code" binding:"required"`
}

type LoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

type emailVerifyRequest struct {
	Email string `json:"email" binding:"required,email"`
}

type AuthResponse struct {
	Success bool   `json:"success"`
	Message string `json:"message"`
	UserID  uint   `json:"user_id,omitempty"`
	Token   string `json:"token,omitempty"`
}

// 用户注册
func Register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, AuthResponse{
			Success: false,
			Message: "请求参数错误: " + err.Error(),
		})
		return
	}

	// 检查用户名是否已存在
	var existingUser models.User
	if err := database.DB.Where("username = ?", req.Username).First(&existingUser).Error; err == nil {
		c.JSON(http.StatusBadRequest, AuthResponse{
			Success: false,
			Message: "用户名已存在",
		})
		return
	}

	// 检查邮箱是否已存在
	if err := database.DB.Where("email = ?", req.Email).First(&existingUser).Error; err == nil {
		c.JSON(http.StatusBadRequest, AuthResponse{
			Success: false,
			Message: "邮箱已存在",
		})
		return
	}
	//查询验证码表查看验证码是否正确
	var emailVerify models.VerificationCode
	if err := database.DB.Where("email = ?", req.Email).First(&emailVerify).Error; err == nil {
		if emailVerify.Code != req.Code {
			c.JSON(http.StatusBadRequest, AuthResponse{
				Success: false,
				Message: "验证码错误",
			})
			return
		}
	}

	// 创建新用户
	user := models.User{
		Username: req.Username,
		Email:    req.Email,
	}

	if err := user.HashPassword(req.Password); err != nil {
		c.JSON(http.StatusInternalServerError, AuthResponse{
			Success: false,
			Message: "密码加密失败",
		})
		return
	}

	if err := database.DB.Create(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, AuthResponse{
			Success: false,
			Message: "用户创建失败",
		})
		return
	}

	c.JSON(http.StatusOK, AuthResponse{
		Success: true,
		Message: "注册成功",
		UserID:  user.ID,
	})
}

// 用户登录
func Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, AuthResponse{
			Success: false,
			Message: "请求参数错误: " + err.Error(),
		})
		return
	}

	// 查找用户
	var user models.User
	if err := database.DB.Where("username = ?", req.Username).First(&user).Error; err != nil {
		c.JSON(http.StatusUnauthorized, AuthResponse{
			Success: false,
			Message: "用户名或密码错误",
		})
		return
	}

	// 验证密码
	if err := user.CheckPassword(req.Password); err != nil {
		c.JSON(http.StatusUnauthorized, AuthResponse{
			Success: false,
			Message: "用户名或密码错误",
		})
		return
	}

	// 生成JWT Token
	token, err := utils.GenerateToken(&user)
	if err != nil {
		c.JSON(http.StatusInternalServerError, AuthResponse{
			Success: false,
			Message: "Token生成失败",
		})
		return
	}

	c.JSON(http.StatusOK, AuthResponse{
		Success: true,
		Message: "登录成功",
		UserID:  user.ID,
		Token:   token,
	})
}

// 验证Token
func VerifyToken(c *gin.Context) {
	tokenString := c.GetHeader("Authorization")
	if tokenString == "" {
		c.JSON(http.StatusUnauthorized, AuthResponse{
			Success: false,
			Message: "缺少Token",
		})
		return
	}

	// 移除 "Bearer " 前缀
	if len(tokenString) > 7 && tokenString[:7] == "Bearer " {
		tokenString = tokenString[7:]
	}

	claims, err := utils.ValidateToken(tokenString)
	if err != nil {
		c.JSON(http.StatusUnauthorized, AuthResponse{
			Success: false,
			Message: "Token无效",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success":  true,
		"message":  "Token有效",
		"user_id":  claims.UserID,
		"username": claims.Username,
	})
}

// 邮箱验证码发送
func SendEmailCode(c *gin.Context) {
	var req emailVerifyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "参数错误",
		})
		return
	}
	// 邮箱配置
	host := "smtp.163.com"
	port := 25
	username := "13403488056@163.com"
	password := "XZcJyD7eCRnLcmDJ" // 163邮箱授权码
	from := "13403488056@163.com"
	to := req.Email

	//构建验证码
	runes := []rune("0123456789")
	b := make([]rune, 6)
	for i := range b {
		b[i] = runes[rand.Intn(len(runes))]
	}

	// 创建邮件消息
	m := gomail.NewMessage()
	m.SetHeader("From", from)
	m.SetHeader("To", to)
	m.SetHeader("Subject", "欢迎您使用《星记事》！")
	m.SetBody("text/plain", "您的验证码为："+string(b)+"，请勿泄露给其他人。")

	// 创建拨号器并发送邮件
	d := gomail.NewDialer(host, port, username, password)

	if err := d.DialAndSend(m); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"Success": false, "error": "邮件发送失败"})
		return
	}
	//将验证码添加到数据库中
	emailVerify := models.VerificationCode{
		Code:        string(b),
		Email:       req.Email,
		ExpiredTime: time.Now().Add(time.Minute * 10).Unix(), //5分钟过期
	}
	//判断是否已存在
	if err := database.DB.Where("email = ?", req.Email).First(&emailVerify).Error; err == nil {
		//是否过期
		if emailVerify.ExpiredTime < time.Now().Unix() {
			//更新验证码
			emailVerify.Code = string(b)
			emailVerify.ExpiredTime = time.Now().Add(time.Minute * 10).Unix()
			database.DB.Save(&emailVerify)
		} else {
			//删除验证码
			database.DB.Delete(&emailVerify)
		}
	} else {
		//创建验证码
		database.DB.Create(&emailVerify)
	}

	c.JSON(http.StatusOK, gin.H{"Success": true, "message": "验证码已发送至您的邮箱"})

}

// 获取用户信息
func GetUserInfo(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"message": "无法获取用户信息",
		})
		return
	}

	var user models.User
	if err := database.DB.First(&user, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"message": "用户不存在",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"id":       user.ID,
			"username": user.Username,
			"email":    user.Email,
		},
	})
}
