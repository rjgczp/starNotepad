package models

import (
	"time"

	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type User struct {
	gorm.Model
	Username          string     `gorm:"uniqueIndex;size:50" json:"username"`
	Email             string     `gorm:"uniqueIndex;size:100" json:"email"`
	PasswordHash      string     `gorm:"size:255" json:"-"`
	Avatar            string     `json:"avatar" gorm:"type:varchar(255);not null"`
	Nickname          string     `json:"nickname" gorm:"type:varchar(255);not null"`
	Signature         string     `json:"signature" gorm:"type:varchar(255);not null"`
	IsAdmin           bool       `json:"is_admin" gorm:"type:bool;not null"`
	IsPlus            bool       `json:"is_plus" gorm:"type:bool;not null"`
	IsPlusExpiredTime *time.Time `json:"is_plus_expired_time" gorm:"type:datetime;default:NULL"`
}

// 加密密码
func (u *User) HashPassword(password string) error {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return err
	}
	u.PasswordHash = string(bytes)
	return nil
}

// 验证密码
func (u *User) CheckPassword(password string) error {
	return bcrypt.CompareHashAndPassword([]byte(u.PasswordHash), []byte(password))
}
