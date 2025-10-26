package models

import (
	"time"

	"gorm.io/gorm"
)

type Notepad struct {
	gorm.Model
	Title       string     `json:"title" gorm:"type:varchar(255);not null"`      //标题
	ContentHtml string     `json:"content_html" gorm:"type:text;not null"`       //内容HTML
	Content     string     `json:"content" gorm:"type:text;not null"`            //内容
	UserID      uint       `json:"user_id" gorm:"type:int;not null"`             //用户ID
	CreatedAt   time.Time  `json:"created_at" gorm:"type:datetime;not null"`     //创建时间
	UpdatedAt   time.Time  `json:"updated_at" gorm:"type:datetime;not null"`     //更新时间
	DeletedAt   *time.Time `json:"deleted_at" gorm:"type:datetime;default:NULL"` //删除时间
	IsDeleted   bool       `json:"is_deleted" gorm:"type:bool;not null"`         //是否删除
	IsInform    bool       `json:"is_inform" gorm:"type:bool;not null"`          //是否通知
	Color       string     `json:"color" gorm:"type:varchar(255);not null"`      //颜色
	CategoryID  uint       `json:"category_id" gorm:"type:int;not null"`         //分类ID
	Icon        string     `json:"icon" gorm:"type:varchar(255);not null"`       //图标
	IsTop       bool       `json:"is_top" gorm:"type:bool;not null"`             //是否置顶
}

type NotepadCategory struct {
	gorm.Model
	UserID    uint   `json:"user_id" gorm:"type:int;not null"`        //添加该分类的用户ID
	Name      string `json:"name" gorm:"type:varchar(255);not null"`  //分类名称
	Icon      string `json:"icon" gorm:"type:varchar(255);not null"`  //图标
	Color     string `json:"color" gorm:"type:varchar(255);not null"` //颜色
	IsDefault bool   `json:"is_default" gorm:"type:bool;not null"`    //是否为默认分类
}
