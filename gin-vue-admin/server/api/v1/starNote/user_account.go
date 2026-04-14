package starNote

import (
	"net/http"
	"time"

	"github.com/flipped-aurora/gin-vue-admin/server/global"
	"github.com/flipped-aurora/gin-vue-admin/server/model/common/response"
	"github.com/flipped-aurora/gin-vue-admin/server/model/starNote"
	starNoteReq "github.com/flipped-aurora/gin-vue-admin/server/model/starNote/request"
	"github.com/flipped-aurora/gin-vue-admin/server/utils"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

type UserAccountApi struct{}

// CreateUserAccount 创建用户账号
// @Tags UserAccount
// @Summary 创建用户账号
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body starNote.UserAccount true "创建用户账号"
// @Success 200 {object} response.Response{msg=string} "创建成功"
// @Router /ua/createUserAccount [post]
func (uaApi *UserAccountApi) CreateUserAccount(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	var ua starNote.UserAccount
	err := c.ShouldBindJSON(&ua)
	if err != nil {
		response.FailWithMessage(err.Error(), c)
		return
	}
	err = uaService.CreateUserAccount(ctx, &ua)
	if err != nil {
		global.GVA_LOG.Error("创建失败!", zap.Error(err))
		response.FailWithMessage("创建失败:"+err.Error(), c)
		return
	}
	response.OkWithMessage("创建成功", c)
}

// Login 用户账号登录
// @Tags UserAccount
// @Summary 用户账号登录
// @Accept application/json
// @Produce application/json
// @Param data body starNoteReq.UserAccountLogin true "用户名/邮箱/手机 + 密码"
// @Success 200 {object} response.Response{data=object,msg=string} "返回token与用户信息"
// @Router /ua/login [post]
func (uaApi *UserAccountApi) Login(c *gin.Context) {
	ctx := c.Request.Context()
	var req starNoteReq.UserAccountLogin
	if err := c.ShouldBindJSON(&req); err != nil {
		c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"data":    gin.H{},
			"message": "参数错误",
		})
		return
	}
	ua, needEmailVerify, challengeID, err := uaService.LoginWithDevice(ctx, req)
	if err != nil {
		global.GVA_LOG.Error("登录失败!", zap.Error(err))
		msg := "登录失败"
		switch err.Error() {
		case "record not found":
			msg = "用户不存在"
		case "password incorrect":
			msg = "密码错误"
		case "password required":
			msg = "请输入密码"
		case "username or emailPhone required":
			msg = "请输入用户名或邮箱"
		case "deviceId required":
			msg = "缺少设备标识"
		case "password not set":
			msg = "该账号未设置密码"
		case "db not init":
			msg = "服务器内部错误"
		}
		c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
			"code":    http.StatusUnauthorized,
			"data":    gin.H{},
			"message": msg,
		})
		return
	}
	if needEmailVerify {
		c.JSON(http.StatusOK, gin.H{
			"code": http.StatusOK,
			"data": gin.H{
				"needEmailVerify": true,
				"challengeId":     challengeID,
			},
			"message": "需要邮箱验证",
		})
		return
	}

	token, claims, err := utils.LoginToken(&ua)
	if err != nil {
		global.GVA_LOG.Error("获取token失败!", zap.Error(err))
		c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
			"code":    http.StatusInternalServerError,
			"data":    gin.H{},
			"message": "服务器内部错误",
		})
		return
	}
	utils.SetToken(c, token, int(claims.RegisteredClaims.ExpiresAt.Unix()-time.Now().Unix()))
	c.JSON(http.StatusOK, gin.H{
		"code": http.StatusOK,
		"data": gin.H{
			"user": gin.H{
				"id":         ua.ID,
				"username":   ua.Username,
				"emailPhone": ua.EmailPhone,
				"nickname":   ua.Nickname,
				"avatar":     ua.Avatar,
				"gender":     ua.Gender,
				"address":    ua.Address,
				"signature":  ua.Signature,
			},
			"token":     token,
			"expiresAt": claims.RegisteredClaims.ExpiresAt.Unix() * 1000,
		},
		"message": "登录成功",
	})
}

func (uaApi *UserAccountApi) SendChangePasswordEmailCode(c *gin.Context) {
	ctx := c.Request.Context()
	var req starNoteReq.SendChangePasswordEmailCodeReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"data":    gin.H{},
			"message": "参数错误",
		})
		return
	}
	if err := uaService.SendChangePasswordEmailCode(ctx, req); err != nil {
		global.GVA_LOG.Error("发送验证码失败!", zap.Error(err))
		c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
			"code":    http.StatusInternalServerError,
			"data":    gin.H{},
			"message": "服务器内部错误",
		})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"code":    http.StatusOK,
		"data":    gin.H{},
		"message": "验证码已发送",
	})
}

func (uaApi *UserAccountApi) ChangePassword(c *gin.Context) {
	ctx := c.Request.Context()
	var req starNoteReq.ChangePasswordReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"data":    gin.H{},
			"message": "参数错误",
		})
		return
	}
	if err := uaService.ChangePassword(ctx, req); err != nil {
		global.GVA_LOG.Error("修改密码失败!", zap.Error(err))
		c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
			"code":    http.StatusInternalServerError,
			"data":    gin.H{},
			"message": "修改密码失败",
		})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"code":    http.StatusOK,
		"data":    gin.H{},
		"message": "修改成功",
	})
}

// Register 用户账号注册
// @Tags UserAccount
// @Summary 用户账号注册
// @Accept application/json
// @Produce application/json
// @Param data body starNoteReq.UserAccountRegister true "用户注册信息"
// @Success 200 {object} response.Response{data=object,msg=string} "返回用户信息"
// @Router /ua/register [post]
func (uaApi *UserAccountApi) Register(c *gin.Context) {
	ctx := c.Request.Context()
	var req starNoteReq.UserAccountRegister
	if err := c.ShouldBindJSON(&req); err != nil {
		c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"data":    gin.H{},
			"message": "参数错误",
		})
		return
	}
	ua, err := uaService.Register(ctx, req)
	if err != nil {
		global.GVA_LOG.Error("注册失败!", zap.Error(err))
		msg := "注册失败"
		switch err.Error() {
		case "emailCode invalid":
			msg = "验证码无效或已过期"
		case "emailCode attempts exceeded":
			msg = "验证码错误次数过多，请重新获取"
		case "emailPhone limit exceeded":
			msg = "该邮箱注册账号已达上限"
		case "emailPhone ambiguous":
			msg = "该邮箱已关联多个账号，请使用用户名"
		case "username already exists":
			msg = "用户名已存在"
		case "emailPhone must be email":
			msg = "邮箱格式不正确"
		case "email invalid":
			msg = "邮箱格式不正确"
		case "username required":
			msg = "请输入用户名"
		case "emailPhone required":
			msg = "请输入邮箱"
		case "password required":
			msg = "请输入密码"
		case "emailCode required":
			msg = "请输入验证码"
		case "db not init":
			msg = "服务器内部错误"
		}
		c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"data":    gin.H{},
			"message": msg,
		})
		return
	}
	token, claims, err := utils.LoginToken(&ua)
	if err != nil {
		global.GVA_LOG.Error("获取token失败!", zap.Error(err))
		c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
			"code":    http.StatusInternalServerError,
			"data":    gin.H{},
			"message": "服务器内部错误",
		})
		return
	}
	utils.SetToken(c, token, int(claims.RegisteredClaims.ExpiresAt.Unix()-time.Now().Unix()))
	c.JSON(http.StatusCreated, gin.H{
		"code": http.StatusCreated,
		"data": gin.H{
			"user": gin.H{
				"id":         ua.ID,
				"username":   ua.Username,
				"emailPhone": ua.EmailPhone,
				"nickname":   ua.Nickname,
				"avatar":     ua.Avatar,
				"gender":     ua.Gender,
				"address":    ua.Address,
				"signature":  ua.Signature,
			},
			"token":     token,
			"expiresAt": claims.RegisteredClaims.ExpiresAt.Unix() * 1000,
		},
		"message": "注册成功",
	})
}

func (uaApi *UserAccountApi) SendRegisterEmailCode(c *gin.Context) {
	ctx := c.Request.Context()
	var req starNoteReq.SendRegisterEmailCodeReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"data":    gin.H{},
			"message": "参数错误",
		})
		return
	}
	if err := uaService.SendRegisterEmailCode(ctx, req.Email); err != nil {
		global.GVA_LOG.Error("发送验证码失败!", zap.Error(err))
		c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
			"code":    http.StatusInternalServerError,
			"data":    gin.H{},
			"message": "服务器内部错误",
		})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"code":    http.StatusOK,
		"data":    gin.H{},
		"message": "验证码已发送",
	})
}

func (uaApi *UserAccountApi) LoginVerify(c *gin.Context) {
	ctx := c.Request.Context()
	var req starNoteReq.LoginVerifyReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"data":    gin.H{},
			"message": "参数错误",
		})
		return
	}
	ua, err := uaService.LoginVerify(ctx, req)
	if err != nil {
		global.GVA_LOG.Error("邮箱验证失败!", zap.Error(err))
		c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
			"code":    http.StatusUnauthorized,
			"data":    gin.H{},
			"message": "邮箱验证失败",
		})
		return
	}
	token, claims, err := utils.LoginToken(&ua)
	if err != nil {
		global.GVA_LOG.Error("获取token失败!", zap.Error(err))
		c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
			"code":    http.StatusInternalServerError,
			"data":    gin.H{},
			"message": "服务器内部错误",
		})
		return
	}
	utils.SetToken(c, token, int(claims.RegisteredClaims.ExpiresAt.Unix()-time.Now().Unix()))
	c.JSON(http.StatusOK, gin.H{
		"code": http.StatusOK,
		"data": gin.H{
			"user": gin.H{
				"id":         ua.ID,
				"username":   ua.Username,
				"emailPhone": ua.EmailPhone,
				"nickname":   ua.Nickname,
				"avatar":     ua.Avatar,
				"gender":     ua.Gender,
				"address":    ua.Address,
				"signature":  ua.Signature,
			},
			"token":     token,
			"expiresAt": claims.RegisteredClaims.ExpiresAt.Unix() * 1000,
		},
		"message": "登录成功",
	})
}

// DeleteUserAccount 删除用户账号
// @Tags UserAccount
// @Summary 删除用户账号
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body starNote.UserAccount true "删除用户账号"
// @Success 200 {object} response.Response{msg=string} "删除成功"
// @Router /ua/deleteUserAccount [delete]
func (uaApi *UserAccountApi) DeleteUserAccount(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	ID := c.Query("ID")
	err := uaService.DeleteUserAccount(ctx, ID)
	if err != nil {
		global.GVA_LOG.Error("删除失败!", zap.Error(err))
		response.FailWithMessage("删除失败:"+err.Error(), c)
		return
	}
	response.OkWithMessage("删除成功", c)
}

// DeleteUserAccountByIds 批量删除用户账号
// @Tags UserAccount
// @Summary 批量删除用户账号
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Success 200 {object} response.Response{msg=string} "批量删除成功"
// @Router /ua/deleteUserAccountByIds [delete]
func (uaApi *UserAccountApi) DeleteUserAccountByIds(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	IDs := c.QueryArray("IDs[]")
	err := uaService.DeleteUserAccountByIds(ctx, IDs)
	if err != nil {
		global.GVA_LOG.Error("批量删除失败!", zap.Error(err))
		response.FailWithMessage("批量删除失败:"+err.Error(), c)
		return
	}
	response.OkWithMessage("批量删除成功", c)
}

// UpdateUserAccount 更新用户账号
// @Tags UserAccount
// @Summary 更新用户账号
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data body starNote.UserAccount true "更新用户账号"
// @Success 200 {object} response.Response{msg=string} "更新成功"
// @Router /ua/updateUserAccount [put]
func (uaApi *UserAccountApi) UpdateUserAccount(c *gin.Context) {
	// 从ctx获取标准context进行业务行为
	ctx := c.Request.Context()

	var ua starNote.UserAccount
	err := c.ShouldBindJSON(&ua)
	if err != nil {
		response.FailWithMessage(err.Error(), c)
		return
	}
	err = uaService.UpdateUserAccount(ctx, ua)
	if err != nil {
		global.GVA_LOG.Error("更新失败!", zap.Error(err))
		response.FailWithMessage("更新失败:"+err.Error(), c)
		return
	}
	response.OkWithMessage("更新成功", c)
}

// FindUserAccount 用id查询用户账号
// @Tags UserAccount
// @Summary 用id查询用户账号
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param ID query uint true "用id查询用户账号"
// @Success 200 {object} response.Response{data=starNote.UserAccount,msg=string} "查询成功"
// @Router /ua/findUserAccount [get]
func (uaApi *UserAccountApi) FindUserAccount(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	ID := c.Query("ID")
	reua, err := uaService.GetUserAccount(ctx, ID)
	if err != nil {
		global.GVA_LOG.Error("查询失败!", zap.Error(err))
		response.FailWithMessage("查询失败:"+err.Error(), c)
		return
	}
	response.OkWithData(reua, c)
}

// GetUserAccountList 分页获取用户账号列表
// @Tags UserAccount
// @Summary 分页获取用户账号列表
// @Security ApiKeyAuth
// @Accept application/json
// @Produce application/json
// @Param data query starNoteReq.UserAccountSearch true "分页获取用户账号列表"
// @Success 200 {object} response.Response{data=response.PageResult,msg=string} "获取成功"
// @Router /ua/getUserAccountList [get]
func (uaApi *UserAccountApi) GetUserAccountList(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	var pageInfo starNoteReq.UserAccountSearch
	err := c.ShouldBindQuery(&pageInfo)
	if err != nil {
		response.FailWithMessage(err.Error(), c)
		return
	}
	list, total, err := uaService.GetUserAccountInfoList(ctx, pageInfo)
	if err != nil {
		global.GVA_LOG.Error("获取失败!", zap.Error(err))
		response.FailWithMessage("获取失败:"+err.Error(), c)
		return
	}
	response.OkWithDetailed(response.PageResult{
		List:     list,
		Total:    total,
		Page:     pageInfo.Page,
		PageSize: pageInfo.PageSize,
	}, "获取成功", c)
}

// GetUserAccountPublic 不需要鉴权的用户账号接口
// @Tags UserAccount
// @Summary 不需要鉴权的用户账号接口
// @Accept application/json
// @Produce application/json
// @Success 200 {object} response.Response{data=object,msg=string} "获取成功"
// @Router /ua/getUserAccountPublic [get]
func (uaApi *UserAccountApi) GetUserAccountPublic(c *gin.Context) {
	// 创建业务用Context
	ctx := c.Request.Context()

	// 此接口不需要鉴权
	// 示例为返回了一个固定的消息接口，一般本接口用于C端服务，需要自己实现业务逻辑
	uaService.GetUserAccountPublic(ctx)
	response.OkWithDetailed(gin.H{
		"info": "不需要鉴权的用户账号接口信息",
	}, "获取成功", c)
}
