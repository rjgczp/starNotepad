package models

import (
	"time"

	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type User struct {
	gorm.Model
	Username     string     `gorm:"uniqueIndex;size:50" json:"username"`         //用户名
	Email        string     `gorm:"uniqueIndex;size:100" json:"email"`           //邮箱
	Phone        string     `gorm:"uniqueIndex;size:11" json:"phone"`            //手机号
	PasswordHash string     `gorm:"size:255" json:"-"`                           //密码
	Avatar       string     `json:"avatar" gorm:"type:varchar(255);not null"`    //头像
	Nickname     string     `json:"nickname" gorm:"type:varchar(255);not null"`  //昵称
	Birthday     *time.Time `json:"birthday" gorm:"type:datetime;default:NULL"`  //生日
	Signature    string     `json:"signature" gorm:"type:varchar(255);not null"` //签名
	IsAdmin      bool       `json:"is_admin" gorm:"type:bool;not null"`          //是否为管理员
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
