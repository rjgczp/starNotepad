
// 自动生成模板NoteModel
package starNote
import (
	"github.com/flipped-aurora/gin-vue-admin/server/global"
	"time"
)

// 记事本 结构体  NoteModel
type NoteModel struct {
    global.GVA_MODEL
  ID  *int64 `json:"id" form:"id" gorm:"primarykey;comment:唯一标识;column:id;"`  //唯一ID
  UserID  *int64 `json:"userID" form:"userID" gorm:"comment:关联 users 表;column:user_id;"`  //所属用户
  CategoryID  *int64 `json:"categoryID" form:"categoryID" gorm:"comment:选择分类;column:category_id;"`  //分类 ID
  Title  *string `json:"title" form:"title" gorm:"comment:输入事件标题;column:title;"`  //标题
  Content  *string `json:"content" form:"content" gorm:"comment:输入内容;column:content;type:text;"`  //正文
  IsTop  *bool `json:"isTop" form:"isTop" gorm:"comment:是否置顶;column:is_top;"`  //是否置顶
  Remind  *bool `json:"remind" form:"remind" gorm:"comment:是否发送通知;column:remind;"`  //是否提醒
  Color  *string `json:"color" form:"color" gorm:"comment:选择颜色;column:color;"`  //背景颜色
  Icon  *string `json:"icon" form:"icon" gorm:"comment:选择图标;column:icon;"`  //图标名称
  IsHighlight  *bool `json:"isHighlight" form:"isHighlight" gorm:"comment:文本高亮显示 Plus;column:is_highlight;"`  //文本高亮
  RecordedAt  *time.Time `json:"recordedAt" form:"recordedAt" gorm:"comment:2025-09-01 星期一;column:recorded_at;"`  //记录时间
}


// TableName 记事本 NoteModel自定义表名 notes
func (NoteModel) TableName() string {
    return "notes"
}





