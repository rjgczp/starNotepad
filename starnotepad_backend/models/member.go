package models

import (
	"time"

	"gorm.io/gorm"
)

type Member struct {
	gorm.Model
	UserID            uint       `gorm:"type:int;not null;index"`     //用户ID
	MemberStatus      string     `gorm:"type:varchar(255);not null"`  //会员状态
	MemberExpiredTime time.Time  `gorm:"type:datetime;default:NULL"`  //会员过期时间
	CreatedAt         time.Time  `gorm:"type:datetime;not null"`      //创建时间
	UpdatedAt         time.Time  `gorm:"type:datetime;not null"`      //更新时间
	DeletedAt         *time.Time `gorm:"type:datetime;default:NULL"`  //删除时间
	RechargeAmount    float64    `gorm:"type:decimal(10,2);not null"` //充值总金额
}
