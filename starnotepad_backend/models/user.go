package models

import (
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type User struct {
	gorm.Model
	Username           string `gorm:"uniqueIndex;size:50" json:"username"`
	Email              string `gorm:"uniqueIndex;size:100" json:"email"`
	PasswordHash       string `gorm:"size:255" json:"-"`
	EmailVerifyRequest string `json:"email_verify_request"`
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
