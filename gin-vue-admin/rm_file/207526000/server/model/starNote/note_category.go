
// 自动生成模板NoteCategory
package starNote
import (
	"github.com/flipped-aurora/gin-vue-admin/server/global"
)

// 记事本分类管理 结构体  NoteCategory
type NoteCategory struct {
    global.GVA_MODEL
  Name  *string `json:"name" form:"name" gorm:"comment:分类名称;column:name;" binding:"required"`  //名称
  Color  *string `json:"color" form:"color" gorm:"comment:分类颜色;column:color;"`  //颜色
  Icon  *string `json:"icon" form:"icon" gorm:"comment:分类图标;column:icon;"`  //图标
}


// TableName 记事本分类管理 NoteCategory自定义表名 note
func (NoteCategory) TableName() string {
    return "note"
}





