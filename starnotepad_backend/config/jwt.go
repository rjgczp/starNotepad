package config

import (
	"time"
)

type JWTConfig struct {
	SecretKey   string
	ExpireHours time.Duration
}

// 生成一个随机的密钥
var JWT = JWTConfig{
	SecretKey:   "your-secret-key-change-in-production", // 生产环境请修改
	ExpireHours: 24 * time.Hour,                         // token有效期24小时
}
