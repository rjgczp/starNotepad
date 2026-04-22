package starNote

import "time"

// UserTag 用户-标签关联关系（已获得标签）。
type UserTag struct {
	UserID    uint      `json:"userID" gorm:"column:user_id;not null;primaryKey"`
	TagID     uint      `json:"tagID" gorm:"column:tag_id;not null;primaryKey"`
	CreatedAt time.Time `json:"createdAt" gorm:"column:created_at;autoCreateTime"`

	User UserAccount `json:"-" gorm:"foreignKey:UserID;references:ID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;"`
	Tag  StarTag     `json:"-" gorm:"foreignKey:TagID;references:ID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;"`
}

func (UserTag) TableName() string {
	return "user_tags"
}

// UserLoginLog 用户登录日记录，用于连续登录标签统计。
type UserLoginLog struct {
	ID        uint      `json:"id" gorm:"primaryKey"`
	UserID    uint      `json:"userID" gorm:"column:user_id;not null;index:idx_user_login_date,priority:1"`
	LoginDate time.Time `json:"loginDate" gorm:"column:login_date;type:date;not null;index:idx_user_login_date,priority:2,unique"`
	CreatedAt time.Time `json:"createdAt" gorm:"column:created_at;autoCreateTime"`

	User UserAccount `json:"-" gorm:"foreignKey:UserID;references:ID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;"`
}

func (UserLoginLog) TableName() string {
	return "user_login_logs"
}

// UserAIPolishLog 用户 AI 润色调用日志。
type UserAIPolishLog struct {
	ID        uint      `json:"id" gorm:"primaryKey"`
	UserID    uint      `json:"userID" gorm:"column:user_id;not null;index"`
	CreatedAt time.Time `json:"createdAt" gorm:"column:created_at;autoCreateTime"`

	User UserAccount `json:"-" gorm:"foreignKey:UserID;references:ID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;"`
}

func (UserAIPolishLog) TableName() string {
	return "user_ai_polish_logs"
}
