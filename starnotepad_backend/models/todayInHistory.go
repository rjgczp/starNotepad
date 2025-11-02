package models

import (
	"time"
)

type TodayInHistory struct {
	ID        uint      `json:"id" gorm:"primaryKey;autoIncrement"`
	CreatedAt time.Time `json:"created_at" gorm:"type:datetime;not null"` //创建时间
	UpdatedAt time.Time `json:"updated_at" gorm:"type:datetime;not null"` //更新时间
	Date      string    `json:"date" gorm:"type:varchar(255);not null"`   //日期
}

type TodayEvent struct {
	ID               uint      `json:"id" gorm:"primaryKey;autoIncrement"`
	TodayInHistoryID uint      `json:"today_in_history_id" gorm:"type:int;not null"` //今日历史ID
	CreatedAt        time.Time `json:"created_at" gorm:"type:datetime;not null"`     //创建时间
	UpdatedAt        time.Time `json:"updated_at" gorm:"type:datetime;not null"`     //更新时间
	Title            string    `json:"title" gorm:"type:varchar(255);not null"`      //事件标题
	Content          string    `json:"content" gorm:"type:text;not null"`            //事件内容
	Image            string    `json:"image" gorm:"type:varchar(255);not null"`      //事件图片
	Link             string    `json:"link" gorm:"type:varchar(255);not null"`       //事件链接
	Source           string    `json:"source" gorm:"type:varchar(255);not null"`     //事件来源
}
