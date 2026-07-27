
// 自动生成模板StarTag
package starNote
import (
	"github.com/flipped-aurora/gin-vue-admin/server/global"
)

// 用户标签 结构体  StarTag
type StarTag struct {
    global.GVA_MODEL
  Name  *string `json:"name" form:"name" gorm:"comment:标签名称;column:name;" binding:"required"`  //标签名
  Color  *string `json:"color" form:"color" gorm:"comment:标签颜色;column:color;" binding:"required"`  //颜色
}


// TableName 用户标签 StarTag自定义表名 star_tags
func (StarTag) TableName() string {
    return "star_tags"
}





