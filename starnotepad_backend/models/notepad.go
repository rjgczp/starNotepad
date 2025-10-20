package models

import (
	"time"

	"gorm.io/gorm"
)

type Notepad struct {
	gorm.Model
	Title      string    `json:"title" gorm:"type:varchar(255);not null"`
	Content    string    `json:"content" gorm:"type:text;not null"	`
	UserID     uint      `json:"user_id" gorm:"type:int;not null"`
	CreatedAt  time.Time `json:"created_at" gorm:"type:datetime;not null"`
	UpdatedAt  time.Time `json:"updated_at" gorm:"type:datetime;not null"`
	DeletedAt  time.Time `json:"deleted_at" gorm:"type:datetime;not null"`
	IsDeleted  bool      `json:"is_deleted" gorm:"type:bool;not null"`
	IsInform   bool      `json:"is_inform" gorm:"type:bool;not null"`
	Color      string    `json:"color" gorm:"type:varchar(255);not null"`
	CategoryID uint      `json:"category_id" gorm:"type:int;not null"`
	Icon       string    `json:"icon" gorm:"type:varchar(255);not null"`
	IsTop      bool      `json:"is_top" gorm:"type:bool;not null"`
}

type Category struct {
	gorm.Model
	Name string `json:"name" gorm:"type:varchar(255);not null"`
	Icon string `json:"icon" gorm:"type:varchar(255);not null"`
}
