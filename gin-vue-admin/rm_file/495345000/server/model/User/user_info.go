// 自动生成模板UserInfo
package User

import (
	"github.com/flipped-aurora/gin-vue-admin/server/global"
)

// 用户信息 结构体  UserInfo
type UserInfo struct {
	global.GVA_MODEL
	Id         *uint   `json:"id" form:"id" gorm:"comment:唯一标识，系统内部使用;column:id;"`                                            //唯一标识
	Username   *string `json:"username" form:"username" gorm:"comment:账号/ID (每月修改一次);column:username;" binding:"required"`    //账号/ID
	Password   *string `json:"password" form:"password" gorm:"comment:登录密码;column:password;" binding:"required"`              //加密密码
	EmailPhone *string `json:"emailPhone" form:"emailPhone" gorm:"comment:手机号码或邮箱 +1;column:email_phone;" binding:"required"` //邮箱或手机
	Nickname   *string `json:"nickname" form:"nickname" gorm:"comment:昵称：查理斯;column:nickname;"`                               //昵称
	Avatar     *string `json:"avatar" form:"avatar" gorm:"comment:用户头像;column:avatar;"`                                       //头像路径
	Gender     *int64  `json:"gender" form:"gender" gorm:"comment:性别选择;column:gender;"`                                       //性别
	Address    *string `json:"address" form:"address" gorm:"comment:中国 山西 +1;column:address;"`                                //现住址
}

// TableName 用户信息 UserInfo自定义表名 user_info
func (UserInfo) TableName() string {
	return "user_info"
}
