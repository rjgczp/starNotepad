
// 自动生成模板UserInfo
package starNodeCore
import (
	"github.com/flipped-aurora/gin-vue-admin/server/global"
)

// 用户信息 结构体  UserInfo
type UserInfo struct {
    global.GVA_MODEL
  Id  *uint `json:"id" form:"id" gorm:"comment:唯一标识;column:id;" binding:"required"`  //唯一标识
  Username  *string `json:"username" form:"username" gorm:"comment:账号/ID;column:username;" binding:"required"`  //账号
  Password  *string `json:"password" form:"password" gorm:"comment:加密密码;column:password;" binding:"required"`  //密码
  EmailPhone  *string `json:"emailPhone" form:"emailPhone" gorm:"comment:邮箱或手机;column:email_phone;"`  //联系方式
  Nickname  *string `json:"nickname" form:"nickname" gorm:"comment:昵称;column:nickname;"`  //昵称
  Avatar  string `json:"avatar" form:"avatar" gorm:"comment:头像路径;column:avatar;"`  //头像
  Gender  string `json:"gender" form:"gender" gorm:"comment:性别;column:gender;type:enum('男','女');"`  //性别
  Address  *string `json:"address" form:"address" gorm:"comment:现住址;column:address;"`  //住址
  Signature  *string `json:"signature" form:"signature" gorm:"comment:签名;column:signature;"`  //签名
}


// TableName 用户信息 UserInfo自定义表名 user_info
func (UserInfo) TableName() string {
    return "user_info"
}





