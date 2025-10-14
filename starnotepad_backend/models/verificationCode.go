package models

type VerificationCode struct {
	Email       string `json:"email" gorm:"type:varchar(100);not null"`
	Code        string `json:"code" gorm:"type:varchar(6);not null"`
	ExpiredTime int64  `json:"expired_time" gorm:"type:bigint;not null"`
}
