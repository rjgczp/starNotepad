// 自动生成模板HistoryDay
package starNote

import (
	"github.com/flipped-aurora/gin-vue-admin/server/global"
)

// 历史上的今天 结构体  HistoryDay
type HistoryDay struct {
	global.GVA_MODEL
	Month    *int64  `json:"month" form:"month" gorm:"comment:关键字段：月份 (1-12);column:month;" binding:"required"`                                  //月份
	Day      *int64  `json:"day" form:"day" gorm:"comment:关键字段：日期 (1-31);column:day;" binding:"required"`                                        //日期
	Year     *int64  `json:"year" form:"year" gorm:"comment:事件发生的年份 (如 1969);column:year;" binding:"required"`                                   //年份
	Title    *string `json:"title" form:"title" gorm:"comment:事件简短标题;column:title;type:text;" binding:"required"`                                //标题
	Summary  *string `json:"summary" form:"summary" gorm:"comment:简评;column:summary;type:text;"`                                                 //简评
	Content  *string `json:"content" form:"content" gorm:"comment:事件详细描述;column:content;type:text;"`                                             //内容
	Quote    *string `json:"quote" form:"quote" gorm:"comment:名言;column:quote;type:text;"`                                                       //名言
	Type     *string `json:"type" form:"type" gorm:"comment:分类 (0:诞辰, 1:祭日, 2:正面的, 3:负面的);column:type;size:'0','1','2','3';" binding:"required"` //分类
	Weight   *int64  `json:"weight" form:"weight" gorm:"comment:权重 (用于当一天有 20 个事件时，决定谁排在最前面);column:weight;"`                                    //权重
	CoverImg string  `json:"coverImg" form:"coverImg" gorm:"comment:封面图 URL (符合数字媒体专业的审美要求);column:cover_img;"`                                  //封面图
}

// TableName 历史上的今天 HistoryDay自定义表名 daily_events
func (HistoryDay) TableName() string {
	return "daily_events"
}
