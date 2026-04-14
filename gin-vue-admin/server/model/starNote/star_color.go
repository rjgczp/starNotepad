
// 自动生成模板StarColor
package starNote
import (
	"github.com/flipped-aurora/gin-vue-admin/server/global"
)

// 星颜色 结构体  StarColor
type StarColor struct {
    global.GVA_MODEL
  Colors  *string `json:"colors" form:"colors" gorm:"column:colors;"`  //颜色
  Userid  *int64 `json:"userid" form:"userid" gorm:"column:userid;"`  //用户ID
  Color  *string `json:"color" form:"color" gorm:"column:color;"`  //颜色值
}


// TableName 星颜色 StarColor自定义表名 star_colors
func (StarColor) TableName() string {
    return "star_colors"
}





