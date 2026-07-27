
// 自动生成模板UserBlog_config
package system
import (
	"github.com/flipped-aurora/gin-vue-admin/server/global"
	"gorm.io/datatypes"
)

// 个人主页 结构体  UserBlog_config
type UserBlog_config struct {
    global.GVA_MODEL
  Blog_config  datatypes.JSON `json:"blog_config" form:"blog_config" gorm:"comment:blog_config;column:blog_config;" swaggertype:"object"`  //个人主页数据
}


// TableName 个人主页 UserBlog_config自定义表名 user_profile
func (UserBlog_config) TableName() string {
    return "user_profile"
}





