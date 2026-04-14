package starNote

import (
	"time"

	"github.com/flipped-aurora/gin-vue-admin/server/global"
)

type UserEmailCode struct {
	global.GVA_MODEL
	UserID       uint       `json:"userId" gorm:"comment:用户ID;column:user_id;index"`
	Email        string     `json:"email" gorm:"comment:邮箱;column:email;index"`
	Scene        string     `json:"scene" gorm:"comment:场景(register/login_new_device);column:scene;index"`
	CodeHash     string     `json:"-" gorm:"comment:验证码hash;column:code_hash"`
	ExpiresAt    time.Time  `json:"expiresAt" gorm:"comment:过期时间;column:expires_at;index"`
	UsedAt       *time.Time `json:"usedAt" gorm:"comment:使用时间;column:used_at"`
	ChallengeID  string     `json:"challengeId" gorm:"comment:登录挑战ID;column:challenge_id;index"`
	DeviceID     string     `json:"deviceId" gorm:"comment:设备ID;column:device_id;index"`
	AttemptCount int        `json:"-" gorm:"comment:尝试次数;column:attempt_count"`
}

func (UserEmailCode) TableName() string {
	return "user_email_codes"
}
