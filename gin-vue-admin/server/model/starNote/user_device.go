package starNote

import "github.com/flipped-aurora/gin-vue-admin/server/global"

type UserDevice struct {
	global.GVA_MODEL
	UserID   uint   `json:"userId" gorm:"comment:用户ID;column:user_id;index"`
	DeviceID string `json:"deviceId" gorm:"comment:设备ID(客户端生成并持久化);column:device_id;size:128;index"`
	Verified bool   `json:"verified" gorm:"comment:是否已验证;column:verified"`
}

func (UserDevice) TableName() string {
	return "user_devices"
}
