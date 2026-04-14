package request

import (
	"time"

	"github.com/flipped-aurora/gin-vue-admin/server/model/common/request"
)

type UserAccountSearch struct {
	CreatedAtRange []time.Time `json:"createdAtRange" form:"createdAtRange[]"`
	request.PageInfo
	Sort  string `json:"sort" form:"sort"`
	Order string `json:"order" form:"order"`
}

type UserAccountLogin struct {
	Username   string `json:"username"`
	EmailPhone string `json:"emailPhone"`
	Password   string `json:"password" binding:"required"`
	DeviceID   string `json:"deviceId"`
}

type UserAccountRegister struct {
	Username   string `json:"username" binding:"required"`
	EmailPhone string `json:"emailPhone" binding:"required"`
	Password   string `json:"password" binding:"required"`
	EmailCode  string `json:"emailCode" binding:"required"`
	DeviceID   string `json:"deviceId"`
	Nickname   string `json:"nickname"`
	Avatar     string `json:"avatar"`
	Gender     string `json:"gender"`
	Address    string `json:"address"`
	Signature  string `json:"signature"`
}

type SendRegisterEmailCodeReq struct {
	Email string `json:"email" binding:"required"`
}

type LoginVerifyReq struct {
	ChallengeID string `json:"challengeId" binding:"required"`
	EmailCode   string `json:"emailCode" binding:"required"`
	DeviceID    string `json:"deviceId" binding:"required"`
}

type SendChangePasswordEmailCodeReq struct {
	Username   string `json:"username"`
	EmailPhone string `json:"emailPhone"`
	DeviceID   string `json:"deviceId"`
}

type ChangePasswordReq struct {
	Username    string `json:"username"`
	EmailPhone  string `json:"emailPhone"`
	NewPassword string `json:"newPassword" binding:"required"`
	EmailCode   string `json:"emailCode" binding:"required"`
	DeviceID    string `json:"deviceId"`
}
